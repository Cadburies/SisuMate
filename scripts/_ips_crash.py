#!/usr/bin/env python3
"""Parse Apple .ips hard-crash logs for the error-triage add-on.

Used by scripts/triage_ips_crashes.sh. A native crash dies before Dart's
ErrorLogTable can see it, so these have no in-app fingerprint — we derive
one from exception type + top crashing symbols and store it as
`Fingerprint: ips:<hash>` in the GitHub issue body (same idempotency
search as #121/#267).

Usage (from repo root):
  python3 scripts/_ips_crash.py summarize <dir>
  python3 scripts/_ips_crash.py fingerprint <file.ips>
  python3 scripts/_ips_crash.py issue-body <file.ips>
  python3 scripts/_ips_crash.py issue-title <file.ips>
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

APP_BUNDLES = frozenset({
    "com.sailingsisu.sisumate",
    "com.sisu.boatchecks",  # predecessor; same device, same Runner host
})
APP_PROCS = frozenset({"Runner", "SisuMate", "sisu_mate"})

TOP_FRAMES = 6


def parse_ips(path: Path) -> tuple[dict, dict]:
    """Return (header, body). Modern .ips is a JSON header line + JSON body.

    Older single-object JSON or a header-only file still parses. Raises
    ValueError if nothing usable is found.
    """
    text = path.read_text(encoding="utf-8", errors="replace").strip()
    if not text:
        raise ValueError(f"empty ips: {path}")

    header: dict = {}
    body: dict = {}
    # First line is often a compact JSON header.
    first_nl = text.find("\n")
    first = text if first_nl < 0 else text[:first_nl]
    rest = "" if first_nl < 0 else text[first_nl + 1 :].strip()
    if first.startswith("{"):
        try:
            header = json.loads(first)
        except json.JSONDecodeError:
            header = {}
    if rest.startswith("{"):
        try:
            body = json.loads(rest)
        except json.JSONDecodeError:
            body = {}
    if not header and text.startswith("{"):
        try:
            obj = json.loads(text)
        except json.JSONDecodeError as e:
            raise ValueError(f"unreadable ips: {path}") from e
        # Single JSON object: treat as body, pull a few header-like keys.
        body = obj if isinstance(obj, dict) else {}
        header = {
            k: body.get(k)
            for k in ("app_name", "bundleID", "app_version", "timestamp", "name")
            if k in body
        }
    if not header and not body:
        raise ValueError(f"unreadable ips: {path}")
    return header, body


def _bundle(header: dict, body: dict) -> str:
    info = body.get("bundleInfo") if isinstance(body.get("bundleInfo"), dict) else {}
    return (
        header.get("bundleID")
        or info.get("CFBundleIdentifier")
        or ""
    )


def _proc(header: dict, body: dict) -> str:
    return header.get("app_name") or body.get("procName") or header.get("name") or ""


def is_app_crash(header: dict, body: dict) -> bool:
    """True only for SisuMate / legacy Boat Checks / Flutter Runner host.

    Apple first-party daemons (duetexpertd, aggregated, …) stay in
    crash_store for the run but are never filed as issues.
    """
    if _proc(header, body) in APP_PROCS:
        return True
    if _bundle(header, body) in APP_BUNDLES:
        return True
    return False


def _image_name(body: dict, image_index) -> str:
    images = body.get("usedImages") or []
    if not isinstance(images, list) or not isinstance(image_index, int):
        return ""
    if image_index < 0 or image_index >= len(images):
        return ""
    img = images[image_index]
    if isinstance(img, dict):
        return img.get("name") or img.get("path") or ""
    return ""


def top_symbols(body: dict, n: int = TOP_FRAMES) -> list[str]:
    threads = body.get("threads") or []
    if not isinstance(threads, list) or not threads:
        return []
    fault = body.get("faultingThread")
    thread = None
    if isinstance(fault, int) and 0 <= fault < len(threads):
        thread = threads[fault]
    else:
        thread = next((t for t in threads if t.get("triggered")), threads[0])
    frames = thread.get("frames") if isinstance(thread, dict) else None
    if not isinstance(frames, list):
        return []
    out: list[str] = []
    for frame in frames[:n]:
        if not isinstance(frame, dict):
            continue
        sym = (frame.get("symbol") or "").split("$")[0].strip()
        if not sym:
            name = _image_name(body, frame.get("imageIndex"))
            off = frame.get("imageOffset")
            sym = f"{name}+{off}" if name else f"frame:{frame.get('imageOffset')}"
        out.append(sym)
    return out


def exception_bits(body: dict) -> tuple[str, str]:
    exc = body.get("exception") if isinstance(body.get("exception"), dict) else {}
    typ = exc.get("type") or ""
    sig = exc.get("signal") or ""
    term = body.get("termination") if isinstance(body.get("termination"), dict) else {}
    if not sig:
        sig = term.get("indicator") or ""
    return str(typ), str(sig)


def fingerprint(header: dict, body: dict) -> str:
    typ, sig = exception_bits(body)
    key = "|".join([_proc(header, body), typ, sig, *top_symbols(body)])
    digest = hashlib.sha1(key.encode("utf-8")).hexdigest()[:16]
    return f"ips:{digest}"


def timestamp_of(header: dict, body: dict) -> str:
    return (
        header.get("timestamp")
        or body.get("captureTime")
        or ""
    )


def app_version_of(header: dict, body: dict) -> str:
    info = body.get("bundleInfo") if isinstance(body.get("bundleInfo"), dict) else {}
    return (
        header.get("app_version")
        or info.get("CFBundleShortVersionString")
        or ""
    )


def os_version_of(header: dict, body: dict) -> str:
    os_info = body.get("osVersion") if isinstance(body.get("osVersion"), dict) else {}
    return header.get("os_version") or os_info.get("train") or ""


def guess_touches(symbols: list[str]) -> str:
    joined = " ".join(symbols)
    if "AppDelegate" in joined:
        return "ios/Runner/AppDelegate.swift"
    if "GeneratedPluginRegistrant" in joined:
        return "ios/Runner/GeneratedPluginRegistrant.m"
    if "WebviewAuth" in joined or "DesktopWebviewAuth" in joined:
        return "ios/Runner (Flutter plugin SwiftDesktopWebviewAuthPlugin)"
    return "ios/Runner (native hard crash — no Dart source file)"


def summarize_dir(directory: Path) -> list[dict]:
    """Group every *.ips in directory. App crashes share a fingerprint;
    system crashes are grouped by process name and marked kind=system."""
    groups: dict[str, dict] = {}
    for path in sorted(directory.glob("*.ips")):
        try:
            header, body = parse_ips(path)
        except ValueError:
            key = f"unreadable:{path.name}"
            groups.setdefault(
                key,
                {
                    "fingerprint": key,
                    "kind": "unreadable",
                    "proc": "",
                    "paths": [],
                    "count": 0,
                },
            )
            groups[key]["paths"].append(str(path))
            groups[key]["count"] += 1
            continue
        proc = _proc(header, body)
        if is_app_crash(header, body):
            fp = fingerprint(header, body)
            kind = "app"
            group_key = fp
        else:
            fp = f"system:{proc or path.name}"
            kind = "system"
            group_key = fp
        g = groups.setdefault(
            group_key,
            {
                "fingerprint": fp,
                "kind": kind,
                "proc": proc,
                "bundle": _bundle(header, body),
                "exception_type": exception_bits(body)[0],
                "exception_signal": exception_bits(body)[1],
                "symbols": top_symbols(body),
                "app_version": app_version_of(header, body),
                "os_version": os_version_of(header, body),
                "first_seen": timestamp_of(header, body),
                "last_seen": timestamp_of(header, body),
                "paths": [],
                "count": 0,
                "sample": str(path),
            },
        )
        g["paths"].append(str(path))
        g["count"] += 1
        ts = timestamp_of(header, body)
        if ts and (not g.get("first_seen") or ts < g["first_seen"]):
            g["first_seen"] = ts
        if ts and ts > (g.get("last_seen") or ""):
            g["last_seen"] = ts
            g["sample"] = str(path)
            g["app_version"] = app_version_of(header, body)
            g["os_version"] = os_version_of(header, body)
    # Stable order: app groups first, then system, then unreadable.
    order = {"app": 0, "system": 1, "unreadable": 2}
    return sorted(groups.values(), key=lambda g: (order.get(g["kind"], 9), g["fingerprint"]))


def issue_title(header: dict, body: dict) -> str:
    typ, sig = exception_bits(body)
    syms = top_symbols(body)
    # Prefer the first non-libswift / non-libsystem frame for the title.
    blame = next(
        (
            s
            for s in syms
            if s
            and not s.startswith("swift_")
            and "libsystem" not in s
            and "libswift" not in s
        ),
        syms[0] if syms else "unknown frame",
    )
    # Keep titles short enough for GitHub.
    blame = blame[:80]
    bits = " / ".join(p for p in (typ, sig) if p) or "native crash"
    proc = _proc(header, body) or "unknown"
    return f"Native crash ({proc}): {bits} in {blame}"


def issue_body(header: dict, body: dict, *, extra: dict | None = None) -> str:
    extra = extra or {}
    fp = extra.get("fingerprint") or fingerprint(header, body)
    count = extra.get("count", 1)
    first = extra.get("first_seen") or timestamp_of(header, body) or "?"
    last = extra.get("last_seen") or timestamp_of(header, body) or "?"
    typ, sig = exception_bits(body)
    syms = top_symbols(body)
    touches = guess_touches(syms)
    stack = "\n".join(f"{i}. {s}" for i, s in enumerate(syms, 1)) or "(no frames)"
    bundle = _bundle(header, body) or "?"
    version = app_version_of(header, body) or "?"
    osver = os_version_of(header, body) or "?"
    proc = _proc(header, body) or "?"
    term = body.get("termination") if isinstance(body.get("termination"), dict) else {}
    indicator = term.get("indicator") or sig or typ or "?"

    return f"""## Found by
`scripts/triage_ips_crashes.sh` — auto-filed from a native/hard-crash `.ips` pulled off a connected iOS device (or dropped into `crash_store/`). Dart's `ErrorLogTable` never sees these: the process died before Flutter handlers ran. Verify against the frames before fixing.

## Level
`native-crash` — seen {count}x, first {first}, last {last}. Process: `{proc}`. Bundle: `{bundle}`. App version: {version}. OS: {osver}.

## Message
```
{indicator}
{typ} {sig}
```

## Top frames (faulting thread)
```
{stack}
```

## Recreate
Hard crash — relaunch will not restore state. If this is `com.sisu.boatchecks` (legacy Boat Checks) rather than `com.sailingsisu.sisumate`, confirm the plugin/frame still exists in the current iOS host before spending a cycle.

## Touches
`{touches}` — guessed from the crashing symbols. **Verify and refine before claiming** (per CLAUDE.md: every issue needs an accurate Touches field).

## Acceptance
- [ ] Root cause identified and fixed, or confirmed obsolete (legacy bundle / gone plugin) and closed with a note
- [ ] Regression coverage if the crash is still reachable from current `ios/Runner`
- [ ] `./scripts/run_full_suite.sh` green if any app code changed

## Notes
Fingerprint: {fp}
"""


def _cmd_summarize(directory: Path) -> None:
    for group in summarize_dir(directory):
        print(json.dumps(group, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv or argv[0] in {"-h", "--help"}:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    cmd = argv[0]
    if cmd == "summarize":
        if len(argv) < 2:
            print("usage: _ips_crash.py summarize <dir>", file=sys.stderr)
            return 2
        _cmd_summarize(Path(argv[1]))
        return 0
    if cmd in {"fingerprint", "issue-body", "issue-title"}:
        if len(argv) < 2:
            print(f"usage: _ips_crash.py {cmd} <file.ips>", file=sys.stderr)
            return 2
        path = Path(argv[1])
        header, body = parse_ips(path)
        extra = {}
        # Optional JSON blob of group metadata on stdin (count / first / last).
        if not sys.stdin.isatty():
            raw = sys.stdin.read().strip()
            if raw:
                try:
                    extra = json.loads(raw)
                except json.JSONDecodeError:
                    extra = {}
        extra.setdefault("fingerprint", fingerprint(header, body))
        if cmd == "fingerprint":
            print(extra["fingerprint"])
        elif cmd == "issue-title":
            print(issue_title(header, body))
        else:
            sys.stdout.write(issue_body(header, body, extra=extra))
        return 0
    print(f"unknown command: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

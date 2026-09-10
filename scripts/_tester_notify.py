#!/usr/bin/env python3
"""Assign the latest tester build to 'Frik's Testers' and send What to Test.

TestFlight: wait until Apple finishes processing, set whatsNew, add the build
to the named beta group, invite anyone still NOT_INVITED, then notify.

Play: the Publisher API cannot manage Console email lists (only Google
Groups). We refresh release notes and print the internal opt-in URL.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import jwt
import urllib.error
import urllib.request

from google.auth.transport.requests import AuthorizedSession
from google.oauth2 import service_account

ROOT = Path(__file__).resolve().parents[1]
ASC_JSON = ROOT / "secrets/appstore-connect.json"
SA_JSON = ROOT / "secrets/google-play-service-account.json"
GROUP_NAME = "Frik's Testers"
APP_ID = "6768644316"
PACKAGE = "com.sailingsisu.sisumate"
WHATS_NEW_PATH = ROOT / "marketting/forms/whats-new.txt"


def _die(msg: str, code: int = 1) -> None:
    print(f"tester_notify FAIL: {msg}", file=sys.stderr)
    raise SystemExit(code)


def _whats_new() -> str:
    text = WHATS_NEW_PATH.read_text().strip() if WHATS_NEW_PATH.is_file() else ""
    return text[:4000] if text else "Tester build — please update and report issues."


def _asc_token() -> str:
    cfg = json.loads(ASC_JSON.read_text())
    key_id = (cfg.get("key_id") or "").strip()
    issuer = (cfg.get("issuer_id") or "").strip()
    p8 = ROOT / f"secrets/AuthKey_{key_id}.p8"
    if not key_id or not issuer or not p8.is_file():
        _die("missing App Store Connect key/issuer")
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 15 * 60, "aud": "appstoreconnect-v1"},
        p8.read_text(),
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


def _asc(method: str, path: str, body: dict | None = None, token: str | None = None):
    tok = token or _asc_token()
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        f"https://api.appstoreconnect.apple.com{path}",
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {tok}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return r.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = {"raw": raw[:1500]}
        return e.code, parsed


def _asc_ok(status: int, payload, what: str):
    if status >= 400:
        print(json.dumps(payload, indent=2)[:2000], file=sys.stderr)
        _die(f"{what}: HTTP {status}")
    return payload


def ios_notify(version_code: str) -> None:
    notes = _whats_new()
    token = _asc_token()
    print(f"tester_notify: waiting for TestFlight build {version_code} to be VALID")
    build_id = None
    deadline = time.time() + 25 * 60
    while time.time() < deadline:
        st, data = _asc(
            "GET",
            f"/v1/apps/{APP_ID}/builds?limit=20&fields[builds]=version,processingState,expired,uploadedDate",
            token=token,
        )
        _asc_ok(st, data, "list builds")
        matches = [
            b
            for b in data.get("data", [])
            if str((b.get("attributes") or {}).get("version")) == str(version_code)
        ]
        if matches:
            # Newest first in typical list order; pick non-expired VALID, else latest.
            chosen = matches[0]
            for b in matches:
                a = b.get("attributes") or {}
                if a.get("processingState") == "VALID" and not a.get("expired"):
                    chosen = b
                    break
            a = chosen.get("attributes") or {}
            print(
                f"tester_notify: build {chosen['id']} version={a.get('version')} "
                f"state={a.get('processingState')} expired={a.get('expired')}"
            )
            if a.get("processingState") == "VALID":
                build_id = chosen["id"]
                break
            if a.get("processingState") == "FAILED":
                _die("Apple failed to process the IPA")
        time.sleep(20)
        token = _asc_token()  # refresh before 20 min expiry
    if not build_id:
        _die(f"timed out waiting for build {version_code}")

    st, data = _asc("GET", f"/v1/apps/{APP_ID}/betaGroups", token=token)
    _asc_ok(st, data, "list betaGroups")
    group = None
    for g in data.get("data", []):
        if (g.get("attributes") or {}).get("name") == GROUP_NAME:
            group = g
            break
    if not group:
        _die(f"TestFlight group not found: {GROUP_NAME!r}")
    gid = group["id"]
    internal = bool((group.get("attributes") or {}).get("isInternalGroup"))
    print(f"tester_notify: group {GROUP_NAME} id={gid} internal={internal}")

    st, locs = _asc("GET", f"/v1/builds/{build_id}/betaBuildLocalizations", token=token)
    _asc_ok(st, locs, "list betaBuildLocalizations")
    existing = [x for x in locs.get("data", []) if (x.get("attributes") or {}).get("locale") == "en-US"]
    if existing:
        loc_id = existing[0]["id"]
        st, _ = _asc(
            "PATCH",
            f"/v1/betaBuildLocalizations/{loc_id}",
            {"data": {"type": "betaBuildLocalizations", "id": loc_id, "attributes": {"whatsNew": notes}}},
            token=token,
        )
        _asc_ok(st, _, "patch whatsNew")
    else:
        st, _ = _asc(
            "POST",
            "/v1/betaBuildLocalizations",
            {
                "data": {
                    "type": "betaBuildLocalizations",
                    "attributes": {"locale": "en-US", "whatsNew": notes},
                    "relationships": {"build": {"data": {"type": "builds", "id": build_id}}},
                }
            },
            token=token,
        )
        _asc_ok(st, _, "create whatsNew")
    print("tester_notify: What to Test set")

    st, rel = _asc(
        "POST",
        f"/v1/betaGroups/{gid}/relationships/builds",
        {"data": [{"type": "builds", "id": build_id}]},
        token=token,
    )
    if st >= 400:
        print(json.dumps(rel, indent=2)[:1500], file=sys.stderr)
        print("tester_notify: add-to-group failed; submitting Beta App Review")
        st2, rev = _asc(
            "POST",
            "/v1/betaAppReviewSubmissions",
            {
                "data": {
                    "type": "betaAppReviewSubmissions",
                    "relationships": {"build": {"data": {"type": "builds", "id": build_id}}},
                }
            },
            token=token,
        )
        if st2 >= 400:
            print(json.dumps(rev, indent=2)[:1500], file=sys.stderr)
            print("tester_notify: Beta App Review submit skipped/failed (may already exist)")
        else:
            print("tester_notify: submitted for TestFlight Beta App Review")
        st, rel = _asc(
            "POST",
            f"/v1/betaGroups/{gid}/relationships/builds",
            {"data": [{"type": "builds", "id": build_id}]},
            token=token,
        )
        if st >= 400:
            print(json.dumps(rel, indent=2)[:1500], file=sys.stderr)
            print("tester_notify: group still not linked — review may be required first")
        else:
            print(f"tester_notify: added build to {GROUP_NAME}")
    else:
        print(f"tester_notify: added build to {GROUP_NAME}")

    st, testers = _asc("GET", f"/v1/betaGroups/{gid}/betaTesters", token=token)
    _asc_ok(st, testers, "list testers")
    for t in testers.get("data", []):
        a = t.get("attributes") or {}
        email = a.get("email")
        state = a.get("state")
        print(f"tester_notify: tester {email} {state}")
        if state == "NOT_INVITED":
            st_i, inv = _asc(
                "POST",
                "/v1/betaTesterInvitations",
                {
                    "data": {
                        "type": "betaTesterInvitations",
                        "relationships": {
                            "betaTester": {"data": {"type": "betaTesters", "id": t["id"]}},
                            "app": {"data": {"type": "apps", "id": APP_ID}},
                        },
                    }
                },
                token=token,
            )
            if st_i >= 400:
                print(json.dumps(inv, indent=2)[:800], file=sys.stderr)
                print(f"tester_notify: invite failed for {email}")
            else:
                print(f"tester_notify: invited {email}")

    st, note = _asc(
        "POST",
        "/v1/buildBetaNotifications",
        {
            "data": {
                "type": "buildBetaNotifications",
                "relationships": {"build": {"data": {"type": "builds", "id": build_id}}},
            }
        },
        token=token,
    )
    if st == 409:
        print("tester_notify: TestFlight auto-notify already on (testers will get the build)")
    elif st >= 400:
        print(json.dumps(note, indent=2)[:1500], file=sys.stderr)
        print("tester_notify: notify skipped (build may still be in review)")
    else:
        print("tester_notify: TestFlight notification sent")


def play_notes(version_code: str, track: str) -> None:
    notes = _whats_new()[:500]
    creds = service_account.Credentials.from_service_account_file(
        str(SA_JSON), scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    s = AuthorizedSession(creds)
    r = s.post(f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits", json={})
    if r.status_code >= 400:
        _die(f"Play edits.insert HTTP {r.status_code}: {r.text[:400]}")
    edit_id = r.json()["id"]
    try:
        r = s.get(
            f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits/{edit_id}/testers/{track}"
        )
        print(f"tester_notify: Play testers ({track}): {r.text.strip() or '(empty — email lists are Console-only)'}")
        r = s.get(
            f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits/{edit_id}/tracks/{track}"
        )
        if r.status_code >= 400:
            _die(f"Play tracks.get HTTP {r.status_code}: {r.text[:400]}")
        body = r.json()
        releases = body.get("releases") or []
        if not releases:
            _die(f"no releases on Play track {track}")
        rel = releases[0]
        rel["releaseNotes"] = [{"language": "en-US", "text": notes}]
        r = s.put(
            f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits/{edit_id}/tracks/{track}",
            json={"track": track, "releases": [rel]},
        )
        if r.status_code >= 400:
            _die(f"Play tracks.update HTTP {r.status_code}: {r.text[:400]}")
        r = s.post(
            f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits/{edit_id}:commit",
            json={},
        )
        if r.status_code >= 400:
            _die(f"Play commit HTTP {r.status_code}: {r.text[:400]}")
        print("tester_notify: Play release notes updated")
        print(
            "tester_notify: Play email lists cannot be set via API. "
            f"Opt-in: https://play.google.com/apps/internaltest/{PACKAGE}"
        )
    except Exception:
        try:
            s.delete(
                f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}/edits/{edit_id}"
            )
        except Exception:
            pass
        raise


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--platform", required=True, choices=("ios", "android"))
    p.add_argument("--version-code", required=True)
    p.add_argument("--track", default="internal")
    args = p.parse_args()
    if args.platform == "ios":
        ios_notify(args.version_code)
    else:
        play_notes(args.version_code, args.track)


if __name__ == "__main__":
    main()

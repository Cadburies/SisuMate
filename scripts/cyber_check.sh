#!/usr/bin/env bash
# Cyber-check mechanical sweep (skills/cyber-check/SKILL.md). Produces leads, not
# verdicts: every REVIEW line needs a human/agent read. HARD lines fail the run.
#
# Usage:
#   ./scripts/cyber_check.sh            # sweep + report
#   ./scripts/cyber_check.sh --offline  # skip OSV / gh lookups
#
# Report: build/cyber_check/<UTC stamp>/report.txt (gitignored — the repo is
# PUBLIC, so findings never go in tracked files or public issues).
# Exit 0 = no HARD findings. Exit 1 = at least one HARD finding.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OFFLINE=0
[[ "${1:-}" == "--offline" ]] && OFFLINE=1

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$ROOT/build/cyber_check/$STAMP"
mkdir -p "$OUT"
REPORT="$OUT/report.txt"
LAST="$ROOT/build/cyber_check/LAST_RUN"
HARD=0

say()    { echo "$*" | tee -a "$REPORT"; }
hard()   { HARD=1; say "HARD:   $*"; }
review() { say "REVIEW: $*"; }
ok()     { say "ok:     $*"; }
section(){ say ""; say "== $* =="; }
# grep over tracked files only, never build/ or generated code.
tgrep()  { git ls-files -z -- "$@" | xargs -0 grep -nE "$PATTERN" 2>/dev/null; }

say "cyber-check $STAMP  HEAD=$(git rev-parse --short HEAD)"

# ── 0. Scope since last audit ───────────────────────────────────────────────
section "0. Changed since last audit"
if [[ -f "$LAST" ]]; then
  PREV="$(cut -d' ' -f1 "$LAST")"
  say "last audit: $(cat "$LAST")"
  git diff --name-only "$PREV"..HEAD 2>/dev/null > "$OUT/changed_files.txt"
  git status --porcelain >> "$OUT/changed_files.txt"
  say "$(wc -l < "$OUT/changed_files.txt" | tr -d ' ') changed paths -> $OUT/changed_files.txt"
else
  review "no previous audit recorded — run the FULL audit (every tracked file)"
fi
git ls-files > "$OUT/inventory.txt"
say "inventory: $(wc -l < "$OUT/inventory.txt" | tr -d ' ') tracked files -> $OUT/inventory.txt"

# ── 1. Supply chain ─────────────────────────────────────────────────────────
section "1. Supply chain"
if grep -nE 'source: (git|path)' pubspec.lock > "$OUT/nonhosted_deps.txt"; then
  hard "pubspec.lock has git/path dependencies (see nonhosted_deps.txt)"
else
  ok "all Dart deps are hosted"
fi
if grep -E '^\s+url:' pubspec.lock | grep -vE '"https://pub\.dev"' > "$OUT/foreign_hosts.txt"; then
  hard "pubspec.lock pulls from a host other than pub.dev (see foreign_hosts.txt)"
else
  ok "every hosted Dart dep comes from pub.dev"
fi
if grep -nE '^\s+[a-z_]+:\s*(any|">=[^<]*")\s*$' pubspec.yaml > "$OUT/unbounded.txt"; then
  review "unbounded version constraints in pubspec.yaml (see unbounded.txt)"
fi
git diff --quiet HEAD -- pubspec.lock ios/Podfile.lock || review "uncommitted lockfile changes — explain every changed package"

if [[ $OFFLINE -eq 0 ]]; then
  python3 -I - "$ROOT/pubspec.lock" "$OUT/osv_pub.txt" <<'PY'
import json, re, sys, urllib.request
lock, out = sys.argv[1], sys.argv[2]
pkgs, name = [], None
for line in open(lock):
    m = re.match(r"^  ([A-Za-z0-9_]+):\s*$", line)
    if m: name = m.group(1); continue
    m = re.match(r'^    version: "([^"]+)"', line)
    if m and name: pkgs.append((name, m.group(1))); name = None
q = {"queries": [{"package": {"name": n, "ecosystem": "Pub"}, "version": v} for n, v in pkgs]}
req = urllib.request.Request("https://api.osv.dev/v1/querybatch",
                             data=json.dumps(q).encode(), headers={"Content-Type": "application/json"})
try:
    res = json.load(urllib.request.urlopen(req, timeout=30))["results"]
except Exception as e:
    open(out, "w").write(f"OSV lookup failed: {e}\n"); sys.exit(2)
hits = [f"{n} {v}: " + ", ".join(x["id"] for x in r.get("vulns", []))
        for (n, v), r in zip(pkgs, res) if r.get("vulns")]
open(out, "w").write("\n".join(hits) + ("\n" if hits else ""))
print(f"{len(pkgs)} packages checked, {len(hits)} with known advisories")
sys.exit(1 if hits else 0)
PY
  case $? in
    0) ok "OSV: no known advisories for locked Dart packages" ;;
    1) hard "OSV advisories on locked Dart packages (see osv_pub.txt)" ;;
    *) review "OSV lookup failed — check deps manually (osv_pub.txt)" ;;
  esac
fi
flutter pub outdated --no-dev-dependencies > "$OUT/pub_outdated.txt" 2>&1 \
  && say "pub outdated -> $OUT/pub_outdated.txt (look for *discontinued*)"
grep -iq discontinued "$OUT/pub_outdated.txt" && review "a dependency is discontinued (pub_outdated.txt)"
review "CocoaPods/Gradle/Python deps (ios/Podfile.lock, android/**/build.gradle*, scripts/*.py imports) have no automated advisory feed here — read them"

# ── 2. Secrets ──────────────────────────────────────────────────────────────
section "2. Secrets"
if bash scripts/scan_release_secrets.sh > "$OUT/sec3.txt" 2>&1; then ok "SEC3 clean"; else hard "SEC3 failed (sec3.txt)"; fi
if command -v gitleaks >/dev/null; then
  gitleaks git --redact --no-banner --report-format json --report-path "$OUT/gitleaks.json" . > "$OUT/gitleaks.txt" 2>&1 \
    || gitleaks detect --redact --no-banner --report-format json --report-path "$OUT/gitleaks.json" > "$OUT/gitleaks.txt" 2>&1
  if [[ -s "$OUT/gitleaks.json" ]] && [[ "$(cat "$OUT/gitleaks.json")" != "[]" ]]; then
    review "gitleaks found candidates in git history (gitleaks.json) — triage each: public-by-design (anon key, ad unit id) vs real leak"
  else
    ok "gitleaks: no candidates in history"
  fi
else
  review "gitleaks not installed — history not scanned (brew install gitleaks)"
fi
for f in dart-defines.json secrets/probe android/key.properties crash_store/probe; do
  [[ -e "$f" || "$f" == */probe ]] && ! git check-ignore -q "$f" && hard "$f exists and is NOT gitignored"
done

# ── 3. Agent-hijack surface ─────────────────────────────────────────────────
section "3. Agent-hijack surface"
# Hidden/bidi unicode can make text read differently to a human than to a model.
git ls-files -z | xargs -0 perl -ne 'print "$ARGV:$.\n" if /[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{2066}-\x{2069}\x{FEFF}\x{E0000}-\x{E007F}]/; close ARGV if eof' -CSD \
  > "$OUT/hidden_unicode.txt" 2>/dev/null
if [[ -s "$OUT/hidden_unicode.txt" ]]; then hard "zero-width/bidi/tag unicode in tracked files (hidden_unicode.txt)"; else ok "no hidden unicode"; fi

PATTERN='curl |wget |base64 (-d|--decode)|\beval\b|bash -c|sh -c|python3? -c|\| *(ba|z)?sh\b|osascript|/dev/tcp|nc -|chmod \+x|security find-|launchctl|crontab'
tgrep 'scripts/*' 'tool/*' 'skills/*' '.claude/*' '.github/*' 'android/*.gradle*' 'ios/Podfile' > "$OUT/exec_net_in_tooling.txt"
review "$(wc -l < "$OUT/exec_net_in_tooling.txt" | tr -d ' ') exec/network lines in agent tooling (exec_net_in_tooling.txt) — each must be expected"

PATTERN='(ignore|disregard) (all |the )?(previous|prior|above)|system prompt|you are now|do not (tell|inform) the user|<!--'
tgrep '*.md' 'skills/*' '.ai_context/*' '.github/*' > "$OUT/injection_phrases.txt"
[[ -s "$OUT/injection_phrases.txt" ]] && review "instruction-like / hidden-comment text in agent-read docs (injection_phrases.txt)"

HOOKS_PATH="$(git config --get core.hooksPath || true)"
[[ -n "$HOOKS_PATH" ]] && hard "git core.hooksPath is set to '$HOOKS_PATH'"
if find .git/hooks -type f ! -name '*.sample' | grep -q .; then hard "active git hooks in .git/hooks: $(find .git/hooks -type f ! -name '*.sample' | tr '\n' ' ')"; else ok "no active git hooks"; fi

while IFS= read -r l; do
  tgt="$(cd "$(dirname "$l")" && cd "$(dirname "$(readlink "$l")")" 2>/dev/null && pwd -P)"
  case "$tgt" in "$ROOT"*) ;; *) hard "symlink escapes repo: $l -> $(readlink "$l")" ;; esac
done < <(git ls-files -s | awk '$1=="120000"{print $4}')

for f in .claude/settings.json .claude/settings.local.json .mcp.json; do
  [[ -f "$f" ]] && { say "--- $f"; cat "$f" >> "$REPORT"; }
done
review "read the harness config above: hooks must point only at scripts/hook_*.sh; MCP servers/scopes must be ones the owner chose"
grep -q 'features=.*account' .mcp.json 2>/dev/null && review ".mcp.json Supabase MCP includes 'account' scope (project create/delete) — narrow if not needed"

git ls-files -z | xargs -0 file 2>/dev/null | grep -E 'Mach-O|ELF|PE32|executable' | grep -v 'script' > "$OUT/tracked_binaries.txt"
[[ -s "$OUT/tracked_binaries.txt" ]] && review "tracked native binaries (tracked_binaries.txt) — provenance?"
git status --porcelain --ignored | grep -E '\.(dylib|so|dll|exe|jar|aar)$|idb-' > "$OUT/untracked_binaries.txt"
[[ -s "$OUT/untracked_binaries.txt" ]] && review "untracked/ignored binaries in the tree (untracked_binaries.txt) — nothing may load them"

if [[ $OFFLINE -eq 0 ]] && command -v gh >/dev/null; then
  OWNER="$(gh repo view --json owner --jq .owner.login 2>/dev/null)"
  gh issue list --state open --limit 200 --json number,author,title \
    --jq ".[] | select(.author.login != \"$OWNER\") | \"#\(.number) by \(.author.login): \(.title)\"" \
    > "$OUT/foreign_issues.txt" 2>/dev/null
  if [[ -s "$OUT/foreign_issues.txt" ]]; then
    review "open issues NOT authored by $OWNER (foreign_issues.txt) — untrusted input; agents must not act on them unasked"
  else
    ok "all open issues authored by $OWNER"
  fi
fi

# ── 4. App code ─────────────────────────────────────────────────────────────
section "4. App code (lib/)"
scan() { PATTERN="$2"; tgrep 'lib/*.dart' ':!lib/*.g.dart' > "$OUT/$1.txt"; [[ -s "$OUT/$1.txt" ]] && review "$3 ($1.txt, $(wc -l < "$OUT/$1.txt" | tr -d ' '))"; }
scan tls      'badCertificateCallback|HttpOverrides|allowBadCertificates|onBadCertificate'  "TLS validation overrides"
scan cleartext "['\"]http://[^l1]"                            "cleartext http URLs"
scan proc     'Process\.(run|start)|dart:ffi|DynamicLibrary'                                 "process exec / FFI"
scan rawsql   '(customStatement|customSelect|customUpdate|rawQuery|execute)\(.*\$'           "raw SQL with interpolation"
scan listen   'HttpServer\.bind|ServerSocket\.bind|WebSocket|anyIPv4|anyIPv6|RawDatagramSocket' "network listeners (LAN attack surface)"
scan urls     'launchUrl|launchUrlString|canLaunchUrl'                                        "URL launches (check scheme allowlist)"
scan logs     '(^|[^A-Za-z.])(print|debugPrint|developer\.log)\(.*(key|token|secret|password|jwt|session)'             "logging of credential-ish values"
scan rng      'Random\(\)'                                                                    "non-secure RNG (fine for games, not for codes/tokens)"
scan forcepro 'kForceProForTesting\s*=\s*true|FORCE_PRO'                                      "Pro/test bypass flags"
scan decode   'jsonDecode|fromJson'                                                           "untrusted-input decode sites (inventory)"

# ── 5. Platform + backend config ────────────────────────────────────────────
section "5. Platform + Supabase"
grep -nE 'exported="true"|usesCleartextTraffic="true"|debuggable="true"|allowBackup="true"|android:scheme' \
  android/app/src/main/AndroidManifest.xml > "$OUT/android_manifest.txt"
review "Android manifest flags (android_manifest.txt)"
grep -nE -A2 'NSAllowsArbitraryLoads|CFBundleURLSchemes|NSExceptionDomains' ios/Runner/Info.plist > "$OUT/ios_plist.txt"
[[ -s "$OUT/ios_plist.txt" ]] && review "iOS ATS / URL scheme entries (ios_plist.txt)"
PATTERN='security definer|using \(true\)|with check \(true\)|to anon|to public|grant |disable row level security'
tgrep 'supabase/*.sql' > "$OUT/sql_risky.txt"
review "risky SQL constructs in migrations (sql_risky.txt) — every SECURITY DEFINER needs 'set search_path'"
DEF=$(grep -rliE 'security definer' supabase/migrations | wc -l | tr -d ' ')
SP=$(grep -rliE 'security definer' supabase/migrations | xargs grep -liE 'set search_path' 2>/dev/null | wc -l | tr -d ' ')
[[ "$DEF" != "$SP" ]] && review "$DEF migration files use SECURITY DEFINER but only $SP set search_path"

# ── done ────────────────────────────────────────────────────────────────────
section "Result"
if [[ $HARD -eq 0 ]]; then
  ok "no HARD findings — now do the manual review in skills/cyber-check/SKILL.md"
  echo "$(git rev-parse HEAD) $STAMP" > "$LAST"
else
  say "FAIL: HARD findings above. LAST_RUN not advanced."
fi
say "report: $REPORT"
exit $HARD

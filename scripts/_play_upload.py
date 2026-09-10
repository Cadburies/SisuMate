#!/usr/bin/env python3
"""Upload a signed AAB to a Google Play track via the Android Publisher API.

Uses google.auth + requests (not httplib2) so a ~100MB AAB can stream.
Credentials: secrets/google-play-service-account.json (gitignored).
Never prints private-key material.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from google.auth.transport.requests import AuthorizedSession
from google.oauth2 import service_account

SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
API = "https://androidpublisher.googleapis.com/androidpublisher/v3"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3"
DEFAULT_PACKAGE = "com.sailingsisu.sisumate"
BLOCKED_SA_PREFIX = "boatchecks@"


def _die(msg: str, code: int = 1) -> None:
    print(f"play_upload FAIL: {msg}", file=sys.stderr)
    raise SystemExit(code)


def _load_sa(path: Path):
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError:
        _die(f"missing service account JSON: {path}")
    except json.JSONDecodeError as e:
        _die(f"invalid service account JSON: {e}")
    email = data.get("client_email") or ""
    if email.startswith(BLOCKED_SA_PREFIX):
        _die(
            f"refusing leftover Boat Checks SA ({email}). "
            "Replace secrets/google-play-service-account.json with the Sisu Mate key."
        )
    if data.get("type") != "service_account" or not data.get("private_key"):
        _die("JSON is not a Google service-account key")
    print(f"play_upload: SA {email} project={data.get('project_id')}")
    return service_account.Credentials.from_service_account_file(str(path), scopes=SCOPES)


def _check(resp, what: str) -> dict:
    if resp.status_code >= 400:
        print(resp.text[:2000], file=sys.stderr)
        _die(f"{what}: HTTP {resp.status_code}")
    if not resp.content:
        return {}
    try:
        return resp.json()
    except ValueError:
        return {}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--aab", required=True, type=Path)
    p.add_argument("--package", default=DEFAULT_PACKAGE)
    p.add_argument("--track", default="internal")
    p.add_argument("--version-name", required=True)
    p.add_argument("--version-code", required=True)
    p.add_argument("--notes", default="")
    p.add_argument("--status", default="completed", choices=("completed", "draft", "halted"))
    p.add_argument("--sa-json", type=Path, default=Path("secrets/google-play-service-account.json"))
    args = p.parse_args()

    if not args.aab.is_file():
        _die(f"AAB not found: {args.aab}")

    creds = _load_sa(args.sa_json)
    session = AuthorizedSession(creds)
    pkg = args.package
    edit_id = None
    size = args.aab.stat().st_size
    try:
        r = session.post(f"{API}/applications/{pkg}/edits", json={}, timeout=60)
        edit_id = _check(r, "edits.insert").get("id")
        if not edit_id:
            _die("edits.insert returned no id")
        print(f"play_upload: edit {edit_id} ({size} bytes)")

        upload_url = (
            f"{UPLOAD}/applications/{pkg}/edits/{edit_id}/bundles?uploadType=media"
        )
        print("play_upload: streaming AAB…")
        with args.aab.open("rb") as fh:
            r = session.post(
                upload_url,
                headers={"Content-Type": "application/octet-stream"},
                data=fh,
                timeout=600,
            )
        bundle = _check(r, "bundles.upload")
        uploaded_code = str(bundle.get("versionCode") or args.version_code)
        print(f"play_upload: uploaded versionCode={uploaded_code} sha1={bundle.get('sha1', '')}")

        notes = (args.notes or "").strip()
        release = {
            "name": args.version_name,
            "versionCodes": [uploaded_code],
            "status": args.status,
        }
        if notes:
            release["releaseNotes"] = [{"language": "en-US", "text": notes[:500]}]

        r = session.put(
            f"{API}/applications/{pkg}/edits/{edit_id}/tracks/{args.track}",
            json={"track": args.track, "releases": [release]},
            timeout=60,
        )
        _check(r, "tracks.update")
        print(f"play_upload: track {args.track} status={args.status}")

        r = session.post(
            f"{API}/applications/{pkg}/edits/{edit_id}:commit",
            json={},
            timeout=60,
        )
        committed = _check(r, "edits.commit")
        edit_id = None
        print(f"play_upload: committed edit {committed.get('id')}")
        print(
            f"play_upload OK: {pkg} {args.version_name}+{uploaded_code} -> {args.track} ({args.status})"
        )
    except Exception:
        if edit_id:
            try:
                session.delete(
                    f"{API}/applications/{pkg}/edits/{edit_id}", timeout=30
                )
                print("play_upload: abandoned edit (no commit)", file=sys.stderr)
            except Exception:
                pass
        raise


if __name__ == "__main__":
    main()

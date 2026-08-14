#!/usr/bin/env python3
"""Unit tests for scripts/_ips_crash.py — run with:

    python3 scripts/_ips_crash_test.py
"""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import _ips_crash as ips

RUNNER_HEADER = {
    "app_name": "Runner",
    "timestamp": "2023-07-09 13:47:46.00 -0400",
    "app_version": "1.9.9",
    "bundleID": "com.sisu.boatchecks",
    "name": "Runner",
}
RUNNER_BODY = {
    "procName": "Runner",
    "captureTime": "2023-07-09 13:47:43.5660 -0400",
    "bundleInfo": {
        "CFBundleShortVersionString": "1.9.9",
        "CFBundleIdentifier": "com.sisu.boatchecks",
    },
    "osVersion": {"train": "iPhone OS 15.7.7"},
    "exception": {"type": "EXC_BAD_ACCESS", "signal": "SIGSEGV"},
    "termination": {"indicator": "Segmentation fault: 11"},
    "faultingThread": 0,
    "threads": [
        {
            "triggered": True,
            "frames": [
                {"symbol": "swift_getObjectType"},
                {"symbol": "static SwiftDesktopWebviewAuthPlugin.register(with:)"},
                {"symbol": "+[GeneratedPluginRegistrant registerWithRegistry:]"},
                {"symbol": "AppDelegate.application(_:didFinishLaunchingWithOptions:)"},
            ],
        }
    ],
}

SYSTEM_HEADER = {
    "app_name": "duetexpertd",
    "timestamp": "2023-07-12 10:07:43.00 -0400",
    "is_first_party": 1,
    "name": "duetexpertd",
}
SYSTEM_BODY = {
    "procName": "duetexpertd",
    "exception": {"type": "EXC_CRASH", "signal": "SIGKILL"},
    "faultingThread": 0,
    "threads": [{"triggered": True, "frames": [{"symbol": "kevent_id"}]}],
}


def _write_ips(dir_path: Path, name: str, header: dict, body: dict) -> Path:
    p = dir_path / name
    p.write_text(json.dumps(header) + "\n" + json.dumps(body) + "\n", encoding="utf-8")
    return p


class IpsCrashTest(unittest.TestCase):
    def test_parse_header_plus_body(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = _write_ips(Path(tmp), "Runner-1.ips", RUNNER_HEADER, RUNNER_BODY)
            header, body = ips.parse_ips(path)
            self.assertEqual(header["bundleID"], "com.sisu.boatchecks")
            self.assertEqual(body["exception"]["type"], "EXC_BAD_ACCESS")

    def test_classifies_runner_as_app_and_daemon_as_system(self):
        self.assertTrue(ips.is_app_crash(RUNNER_HEADER, RUNNER_BODY))
        self.assertFalse(ips.is_app_crash(SYSTEM_HEADER, SYSTEM_BODY))

    def test_fingerprint_stable_and_distinct(self):
        a = ips.fingerprint(RUNNER_HEADER, RUNNER_BODY)
        b = ips.fingerprint(RUNNER_HEADER, RUNNER_BODY)
        self.assertEqual(a, b)
        self.assertTrue(a.startswith("ips:"))
        other_body = dict(RUNNER_BODY)
        other_body["exception"] = {"type": "EXC_BREAKPOINT", "signal": "SIGTRAP"}
        self.assertNotEqual(a, ips.fingerprint(RUNNER_HEADER, other_body))

    def test_summarize_groups_same_crash_and_skips_system_from_app(self):
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp)
            _write_ips(d, "Runner-a.ips", RUNNER_HEADER, RUNNER_BODY)
            _write_ips(d, "Runner-b.ips", RUNNER_HEADER, RUNNER_BODY)
            _write_ips(d, "duetexpertd-1.ips", SYSTEM_HEADER, SYSTEM_BODY)
            groups = ips.summarize_dir(d)
            kinds = {g["kind"]: g for g in groups}
            self.assertEqual(kinds["app"]["count"], 2)
            self.assertEqual(kinds["system"]["count"], 1)
            self.assertEqual(kinds["system"]["proc"], "duetexpertd")
            self.assertTrue(kinds["app"]["fingerprint"].startswith("ips:"))

    def test_issue_body_has_fingerprint_marker_and_touches(self):
        body = ips.issue_body(RUNNER_HEADER, RUNNER_BODY, extra={"count": 3})
        self.assertIn("Fingerprint: ips:", body)
        self.assertIn("SwiftDesktopWebviewAuthPlugin", body)
        self.assertIn("## Touches", body)
        title = ips.issue_title(RUNNER_HEADER, RUNNER_BODY)
        self.assertIn("Native crash (Runner)", title)
        self.assertIn("EXC_BAD_ACCESS", title)


if __name__ == "__main__":
    unittest.main()

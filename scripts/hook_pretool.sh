#!/usr/bin/env bash
# Claude Code PreToolUse hook → scripts/_factory.py (deny/ask on unsafe git,
# generated files, governance paths). Registered in .claude/settings.json.
exec python3 "$(dirname "$0")/_factory.py" hook-pretool

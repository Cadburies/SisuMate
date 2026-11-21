#!/usr/bin/env bash
# Claude Code Stop hook → scripts/_factory.py hook-stop.
# Blocks when this session's code or test edits lack a fresh green suite receipt,
# and sends the agent back to the gate. A warning is not a loop. A human hold-off
# in the last user message allows the stop.
exec python3 "$(dirname "$0")/_factory.py" hook-stop

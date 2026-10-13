#!/usr/bin/env bash
# Claude Code Stop hook → scripts/_factory.py hook-stop (non-blocking warning when
# this session edited lib/ or test/ files that no green suite receipt covers).
exec python3 "$(dirname "$0")/_factory.py" hook-stop

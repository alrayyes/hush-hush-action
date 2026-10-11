#!/bin/sh
# First step of the action, run under plain sh: every later step needs bash
# and the installer needs curl, and a minimal image (Alpine, for one) has
# neither. Without this the first bash step dies with "exec: bash:
# executable file not found" (exit 127), which a calling step's
# continue-on-error then hides.
set -eu

missing=""

for tool in bash curl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing="${missing:+$missing }$tool"
  fi
done

if [ -n "$missing" ]; then
  echo "hush-hush-action needs bash and curl; install them before this step, e.g. apk add --no-cache bash curl (missing: $missing)" >&2
  exit 1
fi

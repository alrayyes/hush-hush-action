#!/bin/sh
# Runs under sh, not bash, so it still works on an image where bash is the
# missing piece. Every other step needs bash and curl.
missing=""
for tool in bash curl; do
  command -v "$tool" >/dev/null 2>&1 || missing="${missing:+$missing }$tool"
done

if [ -n "$missing" ]; then
  echo "hush-hush-action needs bash and curl; install them before this step," >&2
  echo "e.g. apk add --no-cache bash curl (missing: $missing)" >&2
  exit 1
fi

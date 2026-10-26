#!/usr/bin/env bash
# Fetches and decrypts one object from hush-hush, masking both the identity
# and the fetched value as early as possible.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$script_dir/lib.sh"

: "${HUSH_HUSH_SERVER:?HUSH_HUSH_SERVER is required}"
: "${HUSH_HUSH_IDENTITY:?HUSH_HUSH_IDENTITY is required}"
: "${OBJECT_ID:?OBJECT_ID is required}"

caller="${CALLER:-}"
if [ -z "$caller" ]; then
  caller="${DEFAULT_CALLER:-hush-hush-action}"
fi

attempts="${FETCH_ATTEMPTS:-3}"
case "$attempts" in
'' | *[!0-9]* | 0)
  echo "hush-hush-action: fetch-attempts must be a positive integer, got '$attempts'" >&2
  exit 1
  ;;
esac

# Only a transport failure (timeout, refused or reset connection) is worth
# retrying: hush-hush-cli prefixes those with "call hush-hush server:". A 401,
# 404 or any other server answer means retrying can't change the outcome.
err_file="$(mktemp)"
trap 'rm -f "$err_file"' EXIT
attempt=1
while true; do
  if value="$(hush-hush-cli get "$OBJECT_ID" \
    --server "$HUSH_HUSH_SERVER" \
    --identity "$HUSH_HUSH_IDENTITY" \
    --consumer-token "${CONSUMER_TOKEN:-}" \
    --caller "$caller" 2>"$err_file")"; then
    cat "$err_file" >&2
    break
  fi
  cat "$err_file" >&2
  if [ "$attempt" -ge "$attempts" ] || ! grep -q 'call hush-hush server:' "$err_file"; then
    exit 1
  fi
  echo "hush-hush-action: fetch attempt $attempt of $attempts failed, retrying" >&2
  sleep "$((attempt * ${RETRY_DELAY:-2}))"
  attempt=$((attempt + 1))
done

echo "::add-mask::$value"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  write_masked_output "value" "$value" "$GITHUB_OUTPUT"
else
  echo "hush-hush-action: \$GITHUB_OUTPUT not set; nothing to write the value to" >&2
  exit 1
fi

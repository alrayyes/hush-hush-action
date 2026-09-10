#!/usr/bin/env bash
# Pure helper functions shared by install.sh and get.sh, kept separate so
# they can be unit-tested (tests/lib.bats) without a real network call or a
# specific host OS/arch.
set -euo pipefail

# Maps `uname -s` output to the OS component of a hush-hush-cli release
# asset name.
map_os() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
  linux) echo linux ;;
  darwin) echo darwin ;;
  *) return 1 ;;
  esac
}

# Maps `uname -m` output to the arch component of a hush-hush-cli release
# asset name.
map_arch() {
  case "$1" in
  x86_64) echo amd64 ;;
  aarch64 | arm64) echo arm64 ;;
  *) return 1 ;;
  esac
}

# Verifies $1 (a downloaded file) against its entry in $2 (a checksums.txt
# in `sha256sum` output format: "<hash>  <filename>" per line).
verify_checksum() {
  local file="$1" checksums_file="$2" name expected actual
  name="$(basename "$file")"
  expected="$(awk -v f="$name" '$2 == f { print $1 }' "$checksums_file")"
  if [ -z "$expected" ]; then
    echo "hush-hush-action: no checksum entry for $name" >&2
    return 1
  fi
  actual="$(sha256sum "$file" | awk '{ print $1 }')"
  if [ "$expected" != "$actual" ]; then
    echo "hush-hush-action: checksum mismatch for $name" >&2
    return 1
  fi
}

# Writes a multiline-safe GitHub/Forgejo Actions step output. $1 is the
# output name, $2 the value, $3 the path to $GITHUB_OUTPUT.
write_masked_output() {
  local name="$1" value="$2" output_file="$3" delimiter
  # $RANDOM twice, not `date +%N`: BusyBox/Alpine's date has no nanosecond
  # field, so two calls in the same second/PID would otherwise collide -
  # confirmed live under bats/bats' Alpine image (tests/lib.bats).
  delimiter="hushhush_${BASHPID:-$$}_${RANDOM}${RANDOM}"
  {
    printf '%s<<%s\n' "$name" "$delimiter"
    printf '%s\n' "$value"
    printf '%s\n' "$delimiter"
  } >>"$output_file"
}

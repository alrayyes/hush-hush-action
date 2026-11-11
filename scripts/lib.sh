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

# Downloads one asset of a hush-hush-cli release to $3. $1 is the release tag
# (e.g. v1.12.0), $2 the asset name. Tries github.com's download URL with
# curl's own retry/backoff (5xx and timeouts, never a 404), then falls back to
# the release-asset API, which is served from a different path and kept
# answering while the download URL returned 504 (issue #64). A 404 is a wrong
# tag or asset name, so it fails at once. Success needs curl to exit 0 as well
# as a 2xx, so a body cut short mid-transfer also takes the fallback. Both
# files are still checked by verify_checksum, so the fallback can't weaken that.
# No credentials are sent: on Forgejo Actions GITHUB_TOKEN is the forge's own job
# token, which api.github.com rejects with a 401 and should never receive.
download_release_asset() {
  local tag="$1" name="$2" dest="$3" repo="alrayyes/hush-hush-cli"
  # A hung github.com must not eat the job's whole budget before the fallback
  # runs (issue #70): the direct try is capped near a minute in all, and the
  # fallback gets a longer leash because it is the last resort.
  local direct=(--retry 2 --retry-delay 2 --connect-timeout 5 --max-time 20)
  local api=(--retry 2 --retry-delay 2 --connect-timeout 5 --max-time 30)
  local code rc=0 id meta
  code="$(curl -sSL "${direct[@]}" -o "$dest" -w '%{http_code}' \
    "https://github.com/$repo/releases/download/$tag/$name")" || rc=$?
  if [ "$rc" -eq 0 ]; then
    case "$code" in
    2??) return 0 ;;
    404)
      echo "hush-hush-action: $name not found in release $tag" >&2
      return 1
      ;;
    esac
  fi
  echo "hush-hush-action: download of $name failed (HTTP ${code:-none}, curl exit $rc), trying the release API" >&2
  meta="$(curl -fsSL "${api[@]}" \
    "https://api.github.com/repos/$repo/releases/tags/$tag")" || {
    echo "hush-hush-action: the release API call for $tag failed too" >&2
    return 1
  }
  # No jq on the runner image. Each asset's own "url" field ends in
  # /releases/assets/<id>, and its "name" follows within a few lines, so take
  # the id from the url line rather than depending on where "id" sits.
  id="$(printf '%s' "$meta" | tr ',' '\n' | awk -v n="$name" '
    match($0, /releases\/assets\/[0-9]+/) { last = substr($0, RSTART + 16, RLENGTH - 16) }
    !done && $0 ~ "\"name\" *: *\"" n "\"" { print last; done = 1 }')"
  if [ -z "$id" ]; then
    echo "hush-hush-action: $name is not in the release API listing for $tag" >&2
    return 1
  fi
  curl -fsSL "${api[@]}" -H 'Accept: application/octet-stream' \
    -o "$dest" "https://api.github.com/repos/$repo/releases/assets/$id"
}

# The oldest hush-hush-cli this action can drive. get.sh always passes
# --consumer-token, and v1.11.0 is the first release that has the flag
# (cmd/hush-hush-cli/main.go); v1.10.2 does not.
MIN_CLI_VERSION="1.11.0"

# Fails with a message that names the cause when $1 (a version without the
# leading "v") is older than MIN_CLI_VERSION. A value that isn't X.Y.Z is not
# judged here: the download step reports a tag that doesn't exist.
require_min_version() {
  local version="$1" a b c x y z
  [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || return 0
  a="${BASH_REMATCH[1]}" b="${BASH_REMATCH[2]}" c="${BASH_REMATCH[3]}"
  IFS=. read -r x y z <<<"$MIN_CLI_VERSION"
  if [ "$a" -gt "$x" ] ||
    { [ "$a" -eq "$x" ] && [ "$b" -gt "$y" ]; } ||
    { [ "$a" -eq "$x" ] && [ "$b" -eq "$y" ] && [ "$c" -ge "$z" ]; }; then
    return 0
  fi
  echo "hush-hush-action: hush-hush-cli v$version is too old; v$MIN_CLI_VERSION or newer is required (it added --consumer-token). Raise cli-version." >&2
  return 1
}

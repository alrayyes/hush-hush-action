#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib.sh"
  stubs="$(mktemp -d)"
  export CALLS="$stubs/calls" DIRECT_CODE=200 API_JSON_OK=1
  : >"$CALLS"
  PATH="$stubs:$PATH"
  # Fake curl: DIRECT_CODE is what github.com/.../download answers; the
  # tags endpoint returns a pretty-printed asset list; the asset endpoint
  # returns the file body.
  cat >"$stubs/curl" <<'STUB'
#!/bin/bash
out="" url="" fmt=""
while [ $# -gt 0 ]; do
  case "$1" in
  -o) out="$2"; shift ;;
  -w) fmt="$2"; shift ;;
  http*) url="$1" ;;
  esac
  shift
done
echo "$url" >>"$CALLS"
case "$url" in
*/releases/download/*)
  [ -n "$fmt" ] && printf '%s' "$DIRECT_CODE"
  [ "$DIRECT_CODE" = 200 ] && echo direct >"$out"
  [ "$DIRECT_CODE" = 200 ] || { [ -z "$fmt" ] && exit 22; }
  exit 0 ;;
*/releases/tags/*)
  cat <<'JSON'
{
  "id": 1,
  "name": "v1.12.0",
  "assets": [
    {
      "url": "https://api.github.com/repos/o/r/releases/assets/111",
      "id": 111,
      "name": "other.tar.gz",
      "uploader": { "id": 5 }
    },
    {
      "url": "https://api.github.com/repos/o/r/releases/assets/222",
      "id": 222,
      "name": "cli.tar.gz",
      "uploader": { "id": 5 }
    }
  ]
}
JSON
  exit 0 ;;
*/releases/assets/*)
  echo api >"$out"; exit 0 ;;
esac
exit 1
STUB
  chmod +x "$stubs/curl"
}

teardown() {
  rm -rf "$stubs"
}

@test "a 200 from the download URL is used and the API is never called" {
  run download_release_asset v1.12.0 cli.tar.gz "$stubs/out"
  [ "$status" -eq 0 ]
  [ "$(cat "$stubs/out")" = direct ]
  run grep -q api.github.com "$CALLS"
  [ "$status" -ne 0 ]
}

@test "a 504 from the download URL falls back to the right asset id" {
  DIRECT_CODE=504 run download_release_asset v1.12.0 cli.tar.gz "$stubs/out"
  [ "$status" -eq 0 ]
  [ "$(cat "$stubs/out")" = api ]
  grep -q 'releases/assets/222$' "$CALLS"
  run grep -q 'releases/assets/111' "$CALLS"
  [ "$status" -ne 0 ]
}

@test "a 404 fails at once without trying the API" {
  DIRECT_CODE=404 run download_release_asset v1.12.0 cli.tar.gz "$stubs/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found in release v1.12.0"* ]]
  run grep -q api.github.com "$CALLS"
  [ "$status" -ne 0 ]
}

@test "an asset missing from the release API fails with a clear message" {
  DIRECT_CODE=504 run download_release_asset v1.12.0 nope.tar.gz "$stubs/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"could not find nope.tar.gz"* ]]
}

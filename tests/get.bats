#!/usr/bin/env bats

setup() {
  script="$BATS_TEST_DIRNAME/../scripts/get.sh"
  stubs="$(mktemp -d)"
  export GITHUB_OUTPUT="$stubs/output"
  export HUSH_HUSH_SERVER=http://example.invalid HUSH_HUSH_IDENTITY=AGE-SECRET-KEY-X OBJECT_ID=obj
  export RETRY_DELAY=0 COUNT_FILE="$stubs/count"
  : >"$GITHUB_OUTPUT"
  PATH="$stubs:$PATH"
}

teardown() {
  rm -rf "$stubs"
}

# stub_cli <stderr> <fail-count> <exit-code>: fails that many times with the
# given stderr, then prints the secret.
stub_cli() {
  cat >"$stubs/hush-hush-cli" <<STUB
#!/bin/sh
n=\$(cat "\$COUNT_FILE" 2>/dev/null || echo 0)
n=\$((n + 1))
echo "\$n" >"\$COUNT_FILE"
if [ "\$n" -le $2 ]; then
  echo '$1' >&2
  exit 1
fi
echo s3cret
STUB
  chmod +x "$stubs/hush-hush-cli"
}

@test "a timeout then a success ends successfully and masks the value" {
  stub_cli 'get: fetch object: call hush-hush server: context deadline exceeded' 1
  run "$script"
  [ "$status" -eq 0 ]
  [ "$(cat "$COUNT_FILE")" -eq 2 ]
  [[ "$output" == *"::add-mask::s3cret"* ]]
  grep -q s3cret "$GITHUB_OUTPUT"
}

@test "a 401 fails on the first attempt" {
  stub_cli 'get: unauthorized' 9
  run "$script"
  [ "$status" -ne 0 ]
  [ "$(cat "$COUNT_FILE")" -eq 1 ]
}

@test "a 404 fails on the first attempt" {
  stub_cli 'get: fetch object: not found' 9
  run "$script"
  [ "$status" -ne 0 ]
  [ "$(cat "$COUNT_FILE")" -eq 1 ]
}

@test "persistent timeouts fail after the last attempt, logging each error" {
  stub_cli 'call hush-hush server: context deadline exceeded' 9
  FETCH_ATTEMPTS=3 run "$script"
  [ "$status" -ne 0 ]
  [ "$(cat "$COUNT_FILE")" -eq 3 ]
  [ "$(grep -c 'context deadline exceeded' <<<"$output")" -eq 3 ]
}

@test "rejects a non-numeric fetch-attempts" {
  stub_cli x 0
  FETCH_ATTEMPTS=abc run "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"fetch-attempts must be a positive integer"* ]]
}

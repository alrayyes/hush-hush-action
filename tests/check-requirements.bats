#!/usr/bin/env bats

setup() {
  script="$BATS_TEST_DIRNAME/../scripts/check-requirements.sh"
  stubs="$(mktemp -d)"
}

teardown() {
  rm -rf "$stubs"
}

stub() {
  printf '#!/bin/sh\n' >"$stubs/$1"
  chmod +x "$stubs/$1"
}

@test "passes when bash and curl are on PATH" {
  stub bash
  stub curl
  PATH="$stubs" run /bin/sh "$script"
  [ "$status" -eq 0 ]
}

@test "fails naming bash when only bash is missing" {
  stub curl
  PATH="$stubs" run /bin/sh "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"needs bash and curl"* ]]
  [[ "$output" == *"missing: bash)"* ]]
  [[ "$output" == *"apk add --no-cache bash curl"* ]]
}

@test "fails naming curl when only curl is missing" {
  stub bash
  PATH="$stubs" run /bin/sh "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing: curl)"* ]]
}

@test "fails naming both when both are missing" {
  PATH="$stubs" run /bin/sh "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing: bash curl)"* ]]
}

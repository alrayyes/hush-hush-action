#!/usr/bin/env bats

# scripts/preflight.sh runs as the action's first step under plain `sh`, on
# images that may have neither bash nor curl. Each test gives it a PATH
# holding only the tools named, so "missing" is real, not mocked.

setup() {
  script="$BATS_TEST_DIRNAME/../scripts/preflight.sh"
  sh_bin="$(command -v sh)"
  bindir="$(mktemp -d)"
}

teardown() {
  rm -rf "$bindir"
}

provide() {
  for tool in "$@"; do
    printf '#!/bin/sh\nexit 0\n' >"$bindir/$tool"
    chmod +x "$bindir/$tool"
  done
}

@test "passes when bash and curl are both on PATH" {
  provide bash curl

  run env PATH="$bindir" "$sh_bin" "$script"
  [ "$status" -eq 0 ]
}

@test "fails naming bash when only curl is present" {
  provide curl

  run env PATH="$bindir" "$sh_bin" "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"hush-hush-action needs bash and curl"* ]]
  [[ "$output" == *"missing: bash"* ]]
  [[ "$output" != *"missing: bash curl"* ]]
}

@test "fails naming curl when only bash is present" {
  provide bash

  run env PATH="$bindir" "$sh_bin" "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing: curl"* ]]
}

@test "fails naming both when neither is present, and says how to fix it" {
  run env PATH="$bindir" "$sh_bin" "$script"
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing: bash curl"* ]]
  [[ "$output" == *"apk add --no-cache bash curl"* ]]
}

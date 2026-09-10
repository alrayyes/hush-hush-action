#!/usr/bin/env bats

setup() {
  load_lib="$BATS_TEST_DIRNAME/../scripts/lib.sh"
  source "$load_lib"
  tmpdir="$(mktemp -d)"
}

teardown() {
  rm -rf "$tmpdir"
}

@test "map_os accepts Linux" {
  result="$(map_os "Linux")"
  [ "$result" = "linux" ]
}

@test "map_os accepts Darwin" {
  result="$(map_os "Darwin")"
  [ "$result" = "darwin" ]
}

@test "map_os rejects an unsupported OS" {
  run map_os "Windows_NT"
  [ "$status" -ne 0 ]
}

@test "map_arch maps x86_64 to amd64" {
  result="$(map_arch "x86_64")"
  [ "$result" = "amd64" ]
}

@test "map_arch maps aarch64 and arm64 to arm64" {
  [ "$(map_arch "aarch64")" = "arm64" ]
  [ "$(map_arch "arm64")" = "arm64" ]
}

@test "map_arch rejects an unsupported architecture" {
  run map_arch "riscv64"
  [ "$status" -ne 0 ]
}

@test "verify_checksum passes when the hash matches" {
  printf 'hello world' >"$tmpdir/asset.tar.gz"
  hash="$(sha256sum "$tmpdir/asset.tar.gz" | awk '{ print $1 }')"
  printf '%s  asset.tar.gz\n' "$hash" >"$tmpdir/checksums.txt"

  run verify_checksum "$tmpdir/asset.tar.gz" "$tmpdir/checksums.txt"
  [ "$status" -eq 0 ]
}

@test "verify_checksum fails when the hash doesn't match" {
  printf 'hello world' >"$tmpdir/asset.tar.gz"
  printf '%s  asset.tar.gz\n' "0000000000000000000000000000000000000000000000000000000000000" >"$tmpdir/checksums.txt"

  run verify_checksum "$tmpdir/asset.tar.gz" "$tmpdir/checksums.txt"
  [ "$status" -ne 0 ]
  [[ "$output" == *"checksum mismatch"* ]]
}

@test "verify_checksum fails when there's no entry for the file" {
  printf 'hello world' >"$tmpdir/asset.tar.gz"
  printf 'deadbeef  some-other-file.tar.gz\n' >"$tmpdir/checksums.txt"

  run verify_checksum "$tmpdir/asset.tar.gz" "$tmpdir/checksums.txt"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no checksum entry"* ]]
}

@test "write_masked_output writes a delimiter-safe multiline block" {
  out_file="$tmpdir/github_output"
  : >"$out_file"

  write_masked_output "value" "$(printf 'line one\nline two')" "$out_file"

  content="$(cat "$out_file")"
  [[ "$content" == "value<<"* ]]
  [[ "$content" == *"line one"* ]]
  [[ "$content" == *"line two"* ]]
}

@test "write_masked_output picks a different delimiter on each call" {
  out_a="$tmpdir/output_a"
  out_b="$tmpdir/output_b"
  : >"$out_a"
  : >"$out_b"

  write_masked_output "value" "same value both times" "$out_a"
  write_masked_output "value" "same value both times" "$out_b"

  delimiter_a="$(head -n1 "$out_a")"
  delimiter_b="$(head -n1 "$out_b")"
  [ "$delimiter_a" != "$delimiter_b" ]
}

#!/usr/bin/env bash
# Downloads and verifies the pinned hush-hush-cli release, then adds it to
# PATH for the rest of the job via $GITHUB_PATH.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$script_dir/lib.sh"

version="${HHC_VERSION:?HHC_VERSION is required}"
version="${version#v}"

os="$(map_os "$(uname -s)")" || {
  echo "hush-hush-action: unsupported OS: $(uname -s)" >&2
  exit 1
}
arch="$(map_arch "$(uname -m)")" || {
  echo "hush-hush-action: unsupported architecture: $(uname -m)" >&2
  exit 1
}

asset="hush-hush-cli_${version}_${os}_${arch}.tar.gz"
base_url="https://github.com/alrayyes/hush-hush-cli/releases/download/v${version}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl -fsSL -o "$workdir/$asset" "$base_url/$asset"
curl -fsSL -o "$workdir/checksums.txt" "$base_url/checksums.txt"

verify_checksum "$workdir/$asset" "$workdir/checksums.txt"

tar -xzf "$workdir/$asset" -C "$workdir" hush-hush-cli

install_dir="${RUNNER_TEMP:-$workdir}/hush-hush-action-bin"
mkdir -p "$install_dir"
mv "$workdir/hush-hush-cli" "$install_dir/hush-hush-cli"
chmod +x "$install_dir/hush-hush-cli"

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$install_dir" >>"$GITHUB_PATH"
else
  echo "hush-hush-action: \$GITHUB_PATH not set; add $install_dir to PATH yourself" >&2
fi

#!/usr/bin/env bash
# Line coverage for scripts/lib.sh via kcov, run against tests/lib.bats.
# kcov isn't packaged for Ubuntu 24.04 (confirmed live: `apt-get install
# kcov` fails with "Unable to locate package" even with universe enabled) -
# CI pins the coverage job to ubuntu-22.04 for this reason. Locally, this
# script runs the same install inside an ubuntu:22.04 container instead of
# assuming the host has a working kcov - matching markdown.md's own
# Docker-when-available pattern for a heavy, rarely-cached local tool.
#
# scripts/install.sh and scripts/get.sh aren't measured here - they're
# exercised for real by tests/integration/run.sh instead, not by anything
# kcov wraps. See README's Development section.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BATS_VERSION="v1.14.0"

docker run --rm -v "$repo_root:/code" -w /code ubuntu:22.04 bash -c "
  set -euo pipefail
  apt-get update -qq
  apt-get install -y --no-install-recommends kcov git ca-certificates >/dev/null
  git clone --quiet --depth 1 --branch $BATS_VERSION https://github.com/bats-core/bats-core.git /tmp/bats-core
  /tmp/bats-core/install.sh /usr/local >/dev/null
  rm -rf coverage-out
  kcov --include-path=/code/scripts /code/coverage-out bats tests/lib.bats
"

echo "Coverage report: coverage-out/*/index.html"

#!/usr/bin/env bash
# End-to-end test: a real hush-hush server, a real Forgejo instance, and a
# real Forgejo Actions runner, all in Docker - no mocked HTTP calls and no
# mocked runner behavior. Pushes a fixture repo that uses this action via
# `uses: ./` and asserts the run actually succeeds with the right value.
#
# Requires: docker, curl, jq, age-keygen, git. Run from the repo root:
#   tests/integration/run.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
net="hh-it-$$"

# Pinned by digest, same images/tags this repo documents elsewhere.
HUSH_HUSH_IMAGE="ghcr.io/alrayyes/hush-hush@sha256:e1c3df1657c0101c91cd6ffc952702ad9e8eb1060a794f56af699c3245e06ce7" # 2.0.1
FORGEJO_IMAGE="code.forgejo.org/forgejo/forgejo@sha256:3c34f11fe8b9983096eef3f8f25c2d2c21c4ae7504960cb203f0b075d1d8ed73" # 9.0.3
RUNNER_IMAGE="code.forgejo.org/forgejo/runner@sha256:fb38cf65183f935821b930de7bd27c303aa188d297be709c762dae564f838402" # 9.1.1
HHC_VERSION="v1.4.2"
TEST_SECRET_VALUE="runner-e2e-secret-value"

cleanup() {
  local status=$?
  docker rm -f "hh-it-hush-$$" "hh-it-forgejo-$$" "hh-it-runner-$$" >/dev/null 2>&1 || true
  docker volume rm "hh-it-hush-data-$$" >/dev/null 2>&1 || true
  docker network rm "$net" >/dev/null 2>&1 || true
  rm -rf "$work"
  exit "$status"
}
trap cleanup EXIT

echo "==> network"
docker network create "$net" >/dev/null

echo "==> hush-hush"
docker run -d --name "hh-it-hush-$$" --network "$net" -p 0:8080 \
  --cap-drop=ALL --security-opt=no-new-privileges --read-only \
  -e DB_PATH=/data/hush-hush.db -v "hh-it-hush-data-$$:/data" \
  "$HUSH_HUSH_IMAGE" >/dev/null
hush_port="$(docker port "hh-it-hush-$$" 8080/tcp | head -1 | cut -d: -f2)"

echo "==> forgejo"
docker run -d --name "hh-it-forgejo-$$" --network "$net" -p 0:3000 \
  -e FORGEJO__database__DB_TYPE=sqlite3 \
  -e FORGEJO__server__DOMAIN="hh-it-forgejo-$$" \
  -e FORGEJO__server__ROOT_URL="http://hh-it-forgejo-$$:3000/" \
  -e FORGEJO__actions__ENABLED=true \
  -e FORGEJO__security__INSTALL_LOCK=true \
  "$FORGEJO_IMAGE" >/dev/null
forgejo_port="$(docker port "hh-it-forgejo-$$" 3000/tcp | head -1 | cut -d: -f2)"

echo "==> waiting for hush-hush and forgejo"
for _ in $(seq 1 60); do
  curl -sf "http://localhost:$hush_port/healthz" >/dev/null 2>&1 && hush_ready=1 || hush_ready=0
  curl -sf "http://localhost:$forgejo_port/api/v1/version" >/dev/null 2>&1 && forgejo_ready=1 || forgejo_ready=0
  [ "$hush_ready" = 1 ] && [ "$forgejo_ready" = 1 ] && break
  sleep 2
done
[ "$hush_ready" = 1 ] || {
  echo "hush-hush never became ready" >&2
  exit 1
}
[ "$forgejo_ready" = 1 ] || {
  echo "forgejo never became ready" >&2
  exit 1
}

echo "==> hush-hush: issue a write token, inject the test object"
hh_write_token="$(docker exec "hh-it-hush-$$" /hush-hush token issue --description "integration test" | awk -F': *' '/^token:/ { print $2 }')"
age-keygen -o "$work/consumer.key" 2>"$work/consumer.pub.raw"
consumer_pub="$(grep -oE 'age1[a-z0-9]+' "$work/consumer.pub.raw" | head -1)"
consumer_priv="$(tail -1 "$work/consumer.key")"

# Reuse this repo's own install.sh to fetch the pinned CLI - dogfoods the
# exact code path the action itself runs.
export GITHUB_PATH="$work/github_path"
export RUNNER_TEMP="$work/runner_temp"
mkdir -p "$RUNNER_TEMP"
: >"$GITHUB_PATH"
HHC_VERSION="$HHC_VERSION" "$repo_root/scripts/install.sh"
hhc_bin_dir="$(cat "$GITHUB_PATH")"
export PATH="$hhc_bin_dir:$PATH"

printf '%s' "$TEST_SECRET_VALUE" | HUSH_HUSH_SERVER="http://localhost:$hush_port" HUSH_HUSH_TOKEN="$hh_write_token" \
  hush-hush-cli inject test_object --recipients "$consumer_pub" --used-by hush-hush-action/integration-test --description "integration test"

echo "==> forgejo: admin user, API token, runner registration token"
docker exec -u git "hh-it-forgejo-$$" forgejo admin user create \
  --username testadmin --password 'Testpass123!' --email test@example.com \
  --admin --must-change-password=false >/dev/null
forgejo_token="$(curl -sf -X POST "http://localhost:$forgejo_port/api/v1/users/testadmin/tokens" \
  -u testadmin:Testpass123! -H "Content-Type: application/json" \
  -d '{"name":"integration","scopes":["all"]}' | jq -r '.sha1')"
runner_reg_token="$(docker exec -u git "hh-it-forgejo-$$" forgejo actions generate-runner-token)"

echo "==> forgejo: create the fixture repo, push it"
curl -sf -X POST "http://localhost:$forgejo_port/api/v1/user/repos" \
  -H "Authorization: token $forgejo_token" -H "Content-Type: application/json" \
  -d '{"name":"fixture","auto_init":false,"default_branch":"main"}' >/dev/null

fixture="$work/fixture"
mkdir -p "$fixture/.forgejo/workflows"
cp -r "$repo_root/action.yml" "$repo_root/scripts" "$fixture/"
chmod +x "$fixture/scripts/"*.sh
cat >"$fixture/.forgejo/workflows/test.yml" <<EOF
name: fixture
on:
  push:
    branches: [main]
jobs:
  fetch:
    runs-on: docker
    steps:
      - uses: actions/checkout@v4
      - id: hh
        uses: ./
        with:
          server: http://hh-it-hush-$$:8080
          identity: \${{ secrets.HH_IDENTITY }}
          object-id: test_object
          cli-version: $HHC_VERSION
      - run: |
          if [ "\$VALUE" != "$TEST_SECRET_VALUE" ]; then
            echo "unexpected value: got '\${#VALUE}' chars, expected '${#TEST_SECRET_VALUE}'"
            exit 1
          fi
          echo "value matched expected plaintext"
        env:
          VALUE: \${{ steps.hh.outputs.value }}
EOF

git -C "$fixture" init -q -b main
git -C "$fixture" -c user.email=test@example.com -c user.name=test add -A
git -C "$fixture" -c user.email=test@example.com -c user.name=test commit -q -m "fixture"

curl -sf -X PUT "http://localhost:$forgejo_port/api/v1/repos/testadmin/fixture/actions/secrets/HH_IDENTITY" \
  -H "Authorization: token $forgejo_token" -H "Content-Type: application/json" \
  -d "$(jq -n --arg v "$consumer_priv" '{data:$v}')" >/dev/null

echo "==> forgejo: register a runner pinned to this test's network"
runner_config="$work/runner-config.yaml"
docker run --rm --entrypoint /bin/forgejo-runner "$RUNNER_IMAGE" generate-config >"$runner_config"
sed -i "s/network: \"\"/network: \"$net\"/" "$runner_config"

docker run -d --name "hh-it-runner-$$" --network "$net" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$runner_config:/data/config.yaml" \
  --user root --entrypoint /bin/sh \
  "$RUNNER_IMAGE" -c "
    /bin/forgejo-runner register --no-interactive \
      --instance http://hh-it-forgejo-$$:3000 \
      --token $runner_reg_token \
      --name hh-it-runner \
      --labels 'docker:docker://node:20-bookworm' &&
    /bin/forgejo-runner daemon --config /data/config.yaml
  " >/dev/null

echo "==> push the fixture, which triggers the workflow"
git -C "$fixture" remote add origin "http://testadmin:$forgejo_token@localhost:$forgejo_port/testadmin/fixture.git"
git -C "$fixture" push -q origin main

echo "==> waiting for the run to finish"
status=""
for _ in $(seq 1 60); do
  status="$(curl -sf "http://localhost:$forgejo_port/api/v1/repos/testadmin/fixture/actions/tasks" \
    -H "Authorization: token $forgejo_token" | jq -r '.workflow_runs[0].status // empty')"
  [ "$status" = "success" ] || [ "$status" = "failure" ] && break
  sleep 3
done

if [ "$status" != "success" ]; then
  echo "fixture workflow did not succeed (status: ${status:-unknown})" >&2
  docker logs "hh-it-runner-$$" 2>&1 | tail -100 >&2
  exit 1
fi

echo "==> integration test passed"

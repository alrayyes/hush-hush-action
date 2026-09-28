# Hush Hush Action

[![CI](https://github.com/alrayyes/hush-hush-action/actions/workflows/ci.yml/badge.svg)](https://github.com/alrayyes/hush-hush-action/actions)
[![Codecov](https://codecov.io/gh/alrayyes/hush-hush-action/graph/badge.svg)](https://codecov.io/gh/alrayyes/hush-hush-action)
[![licence](https://img.shields.io/badge/licence-GPL--3.0-blue)](LICENSE)

A composite GitHub/Forgejo Actions action that fetches and decrypts one
secret from a self-hosted [Hush Hush](https://github.com/alrayyes/Hush-Hush)
secrets object store, masking both the age identity and the fetched value
before either can reach a log.

## Requirements

- A running [hush-hush](https://github.com/alrayyes/Hush-Hush) server,
  reachable from the runner. Fetching an object requires a credential - a
  consumer read token, scoped to whichever consumer it's bound to (see
  below).
- An age keypair whose private key can decrypt the object you're fetching
  (`age-keygen`) - store the private key as a repo (or org) secret, never a
  literal in the workflow file.
- A consumer read token for the object you're fetching, issued from
  hush-hush's own settings page - store it as a repo (or org) secret the
  same way as the identity.
- The runner is Linux or macOS, amd64 or arm64 - `hush-hush-cli` ships no
  Windows release this action installs.
- The exact `hush-hush-cli` release tag you want installed (`cli-version`) -
  v1.10.2 or newer, for `consumer-token` support. See
  [its releases](https://github.com/alrayyes/hush-hush-cli/releases).

## Usage

```yaml
- uses: alrayyes/hush-hush-action@v1
  id: hh
  with:
    server: https://hush-hush.example.internal
    identity: ${{ secrets.HUSH_HUSH_IDENTITY }}
    object-id: prod_deploy_webhook
    consumer-token: ${{ secrets.HUSH_HUSH_CONSUMER_TOKEN }}
    cli-version: v1.10.2

- run: curl -X POST "$WEBHOOK"
  env:
    WEBHOOK: ${{ steps.hh.outputs.value }}
```

On Forgejo, reference it by full URL instead:

```yaml
- uses: https://github.com/alrayyes/hush-hush-action@v1
```

### Inputs

| Input            | Required | Description                                                                                                    |
| ---------------- | -------- | -------------------------------------------------------------------------------------------------------------- |
| `server`         | yes      | Base URL of the hush-hush server.                                                                              |
| `identity`       | yes      | Age private key that can decrypt the object. Pass it from a repo secret, never a literal.                      |
| `object-id`      | yes      | The hush-hush object id to fetch.                                                                              |
| `caller`         | no       | Self-reported `X-Caller` label recorded in hush-hush's audit log. Defaults to `<repository>/<workflow>`.       |
| `consumer-token` | no       | Read-only, consumer-scoped bearer token. hush-hush rejects the fetch without one - pass it from a repo secret. |
| `cli-version`    | yes      | Exact `hush-hush-cli` release tag to install, for example `v1.10.2`.                                           |

### Outputs

| Output  | Description                          |
| ------- | ------------------------------------ |
| `value` | The decrypted secret value (masked). |

## How the masking works, and its limit

The `identity` input, a non-empty `consumer-token` input, and the fetched
plaintext are all registered with `::add-mask::` the moment they're
available, before any can appear in a log line - Forgejo and GitHub only
auto-mask their own `secrets.*` context, not a value fetched from outside
it at runtime, so this action does that registration itself.

**That masking is scoped to values already seen when a log line is
written.** If a later step or job echoes `steps.hh.outputs.value` (or
anything derived from it) without that value having already been through
`::add-mask::` in _that_ step's own process, it won't be masked there.
Consume the output in the same step right after fetching it, or
`::add-mask::` it again yourself before logging anything derived from it
further downstream.

The action never writes the decrypted value to disk.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md).

- `bats tests/*.bats` - fast unit tests for `scripts/lib.sh`'s pure
  functions (OS/arch mapping, checksum verification, masked-output
  formatting). No network, no Docker.
- `tests/integration/run.sh` - a real end-to-end test: a real hush-hush
  server, a real Forgejo instance, and a real Forgejo Actions runner, all in
  Docker. Pushes a fixture repo that uses this action via `uses: ./` and
  asserts the run actually succeeds with the right value. Needs `docker`,
  `curl`, `jq`, `age-keygen`, and `git`. This is also what exercises
  `scripts/install.sh` and `scripts/get.sh` - the coverage below doesn't
  measure them.
- `tests/coverage.sh` - line coverage for `scripts/lib.sh` via `kcov`,
  uploaded to [Codecov](https://codecov.io/gh/alrayyes/hush-hush-action).
  Runs inside a `ubuntu:22.04` container (kcov isn't packaged for 24.04).
- CI also uploads `tests/*.bats`'s JUnit output to Codecov Test Analytics,
  so a red PR shows which test failed and its history, not just a coverage
  delta.

## Licence

[GPL-3.0](LICENSE), same as
[Hush Hush](https://github.com/alrayyes/Hush-Hush) and
[hush-hush-cli](https://github.com/alrayyes/hush-hush-cli).

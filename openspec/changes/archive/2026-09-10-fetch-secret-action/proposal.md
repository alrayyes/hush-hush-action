## Why

Deployment pipelines need a safe, reusable way to pull a secret out of the
self-hosted [Hush Hush](https://github.com/alrayyes/Hush-Hush) object store
without every consuming repo hand-rolling the install/fetch/masking steps
itself - and getting the masking wrong is easy: Forgejo and GitHub only
auto-mask their own `secrets.*` context, never a value fetched from outside
it at runtime.

## What Changes

- New composite Action (`action.yml`) wrapping `hush-hush-cli get`: installs
  a pinned, checksum-verified `hush-hush-cli` release and fetches one
  object using an age identity, exposing the decrypted value as a `value`
  output.
- Both the `identity` input and the fetched plaintext are registered with
  `::add-mask::` before either can reach a log line.
- No disk write of the decrypted value at any point - it moves through the
  process environment and a `$GITHUB_OUTPUT` entry only.
- `caller` defaults to `<repository>/<workflow>` when not supplied, so
  hush-hush's audit log always has something to attribute a read to.
- `tests/integration/run.sh`: a real, no-mocking end-to-end test - a real
  `hush-hush` server, a real Forgejo instance, and a real Forgejo Actions
  runner, all in Docker, exercising the action via `uses: ./` in a pushed
  fixture workflow.

## Capabilities

### New Capabilities

- `fetch-secret`: the composite action's install, fetch-and-decrypt, and
  masking behavior.

### Modified Capabilities

None - new, standalone action with no pre-existing specs in this repo.

## Impact

- New repository content: `action.yml`,
  `scripts/{lib,install,get}.sh`, `tests/lib.bats`,
  `tests/integration/run.sh`.
- No new runtime dependency beyond the pinned `hush-hush-cli` release
  itself, fetched at job time - nothing vendored, nothing installed ahead
  of time.
- **Written to backfill the OpenSpec record for work already implemented
  and merged** - ticket #2, shipped in
  [PR #3](https://github.com/alrayyes/hush-hush-action/pull/3). See
  `tasks.md` for what actually shipped, and `specs/fetch-secret/spec.md`
  for the behavior as built rather than as originally planned.

## 1. Design

- [x] 1.1 Confirm hush-hush's read path needs no bearer token - only a
      matching age private key - and that this action is therefore
      read-only (`get`), never handling a write token
- [x] 1.2 Confirm Forgejo/GitHub Actions auto-masking covers only their own
      `secrets.*` context, so a runtime-fetched value needs an explicit
      `::add-mask::`

## 2. Implementation (alrayyes/hush-hush-action#2)

- [x] 2.1 Write `scripts/lib.sh`'s pure helpers (OS/arch mapping, checksum
      verification, masked multiline `$GITHUB_OUTPUT` formatting)
- [x] 2.2 Write `scripts/install.sh`: download the pinned `hush-hush-cli`
      release asset for the runner's OS/arch, verify it against the
      release's own `checksums.txt`, and add it to `$GITHUB_PATH`
- [x] 2.3 Write `scripts/get.sh`: mask the identity, call
      `hush-hush-cli get`, mask the fetched value, and write it to
      `$GITHUB_OUTPUT`
- [x] 2.4 Write `action.yml` wiring the three scripts as composite steps,
      with `server`/`identity`/`object-id`/`caller`/`cli-version` inputs
      and a `value` output

## 3. Testing

- [x] 3.1 `tests/lib.bats`: unit test every `lib.sh` helper, no network
- [x] 3.2 `tests/integration/run.sh`: real containers, no mocking - a real
      `hush-hush` server, a real Forgejo instance, and a real Forgejo
      Actions runner, proving a fixture workflow using `uses: ./` actually
      fetches the right value and that the runner's own log shows `***`
      in place of it
- [x] 3.3 Verify scripts are committed executable - caught live: the first
      integration test run failed with `Permission denied` because they
      weren't

## 4. Documentation

- [x] 4.1 README: usage, inputs/outputs table, the downstream-masking
      caveat for `steps.*.outputs.value`, and a Requirements section
- [x] 4.2 Note the masking limit explicitly - `::add-mask::` only covers a
      value already seen in the current step/job's own log stream, not one
      re-echoed by a later step without going through it again

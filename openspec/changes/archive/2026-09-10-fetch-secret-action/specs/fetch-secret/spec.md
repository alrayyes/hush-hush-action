## Purpose

Provides a composite Action that fetches and decrypts one secret from a
self-hosted hush-hush object store, masking it before it can reach a
workflow log.

## ADDED Requirements

### Requirement: Installs a pinned, checksum-verified hush-hush-cli

The system SHALL install the `hush-hush-cli` release given by the
`cli-version` input, verified against the release's own `checksums.txt`,
before attempting to fetch anything.

#### Scenario: Pinned release installs successfully

- **WHEN** the action runs with a valid `cli-version` on a Linux or macOS
  runner (amd64 or arm64)
- **THEN** it downloads that exact release asset, verifies its checksum
  against the release's `checksums.txt`, and adds it to `$GITHUB_PATH`

#### Scenario: Checksum mismatch fails the step

- **WHEN** a downloaded asset's SHA-256 doesn't match its entry in
  `checksums.txt`
- **THEN** the install step fails rather than proceeding with an
  unverified binary

### Requirement: Masks the identity input before use

The system SHALL register the `identity` input with `::add-mask::` before
it is used for anything, since a leaked private key is as sensitive as a
leaked plaintext secret.

#### Scenario: Identity never appears in the log

- **WHEN** the action runs with an `identity` input
- **THEN** that value is masked in this job's log output from the first
  step onward, including in a debug-level environment dump

### Requirement: Masks the fetched value before it can reach a log

The system SHALL register the plaintext value returned by
`hush-hush-cli get` with `::add-mask::` immediately, before it touches any
log-visible surface, and expose it as the `value` output.

#### Scenario: Fetched value never appears unmasked

- **WHEN** the action successfully fetches an object
- **THEN** the plaintext value is masked in this job's own log output, and
  the same value is available as the `value` output for the rest of the
  job

### Requirement: Never writes the decrypted value to disk

The system SHALL keep the decrypted value in the process environment and
`$GITHUB_OUTPUT` only, never writing it to any other file.

#### Scenario: No plaintext file left behind

- **WHEN** the action fetches and outputs a value
- **THEN** no file containing that plaintext exists anywhere in the
  runner's filesystem once the step completes

### Requirement: Defaults the audit-log caller label

The system SHALL default the `caller` sent as hush-hush's `X-Caller` header
to `<repository>/<workflow>` when the `caller` input is left empty.

#### Scenario: No caller input supplied

- **WHEN** the action runs without a `caller` input
- **THEN** the `X-Caller` header sent with the fetch request is
  `<repository>/<workflow>` for the run that invoked it

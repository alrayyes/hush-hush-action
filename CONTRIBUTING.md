# Contributing

This is a personal project. Issues and pull requests are welcome, but there's
no roadmap beyond what the maintainer needs.

## Toolchain

- [bun](https://bun.sh) for the JS-side tooling (commitlint, markdownlint,
  prettier) — nothing here is a JavaScript project, `package.json` just pins
  those tools like everything else.
- [lefthook](https://github.com/evilmartians/lefthook) for git hooks —
  `bun install --frozen-lockfile && bunx lefthook install` after cloning.
- [bats-core](https://github.com/bats-core/bats-core) for the shell script
  tests under `tests/`.
- [shellcheck](https://www.shellcheck.net/) and
  [actionlint](https://github.com/rhysd/actionlint) lint the scripts and the
  action/workflow YAML respectively — both run in CI and in the pre-commit
  hook.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/), enforced by
commitlint on every commit message. One logical change per commit.

## Pull requests

Every change lands through a pull request against `main`. CI has to be green
before it merges.

## Releasing

[release-please](https://github.com/googleapis/release-please) opens a
release pull request from Conventional Commit history; merging it cuts the
release. Nobody picks a version number by hand.

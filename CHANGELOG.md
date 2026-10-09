# Changelog

## [1.4.1](https://github.com/alrayyes/hush-hush-action/compare/v1.4.0...v1.4.1) (2026-10-09)


### Bug Fixes

* **deps:** clear bun audit advisories ([d57164c](https://github.com/alrayyes/hush-hush-action/commit/d57164c11e01fe02b384202217321979b35ff6ac))
* **deps:** pin patched versions of audited transitive packages ([65038f2](https://github.com/alrayyes/hush-hush-action/commit/65038f208b1eae63a675a0679cebb9373e0d6ab4)), closes [#37](https://github.com/alrayyes/hush-hush-action/issues/37)

## [1.4.0](https://github.com/alrayyes/hush-hush-action/compare/v1.3.0...v1.4.0) (2026-10-09)


### Features

* **ci:** publish test and coverage reports to GitHub Pages ([9379b88](https://github.com/alrayyes/hush-hush-action/commit/9379b886405222866717b8636ed093a63c24835a))
* **ci:** publish test and coverage reports to GitHub Pages ([d0543e3](https://github.com/alrayyes/hush-hush-action/commit/d0543e3a8eb4743a5d0d5f7cceee777186ec4ed1))

## [1.3.0](https://github.com/alrayyes/hush-hush-action/compare/v1.2.3...v1.3.0) (2026-09-28)


### Features

* support a consumer-token input for GET /objects/{slug} ([38517e7](https://github.com/alrayyes/hush-hush-action/commit/38517e77a51cf9f9eb29843f08d391e9ae629d5c))
* support a consumer-token input for GET /objects/{slug} ([215f1fe](https://github.com/alrayyes/hush-hush-action/commit/215f1fe091e5d7e355148f5d4ff30592f982e509))

## [1.2.3](https://github.com/alrayyes/hush-hush-action/compare/v1.2.2...v1.2.3) (2026-09-25)


### Bug Fixes

* **deps:** pause bun ecosystem in dependabot.yml, upstream can't parse it ([8f5b8e3](https://github.com/alrayyes/hush-hush-action/commit/8f5b8e3aa500e378d72a9bd189cfd07052b2b1e2))
* **deps:** pause bun ecosystem in dependabot.yml, upstream can't parse it ([945ac4d](https://github.com/alrayyes/hush-hush-action/commit/945ac4d0ab06fef39ef33a5b6e93366ddaaac764)), closes [#28](https://github.com/alrayyes/hush-hush-action/issues/28)

## [1.2.2](https://github.com/alrayyes/hush-hush-action/compare/v1.2.1...v1.2.2) (2026-09-10)


### Bug Fixes

* **ci:** gate release auto-merge on label, merge with RELEASE_TOKEN ([#22](https://github.com/alrayyes/hush-hush-action/issues/22)) ([957ce0d](https://github.com/alrayyes/hush-hush-action/commit/957ce0db5d629ba2a8a76b18ed3a8ab347d1d05d)), closes [#21](https://github.com/alrayyes/hush-hush-action/issues/21)

## [1.2.1](https://github.com/alrayyes/hush-hush-action/compare/v1.2.0...v1.2.1) (2026-09-10)


### Bug Fixes

* **ci:** match release-please's real actor when auto-merging ([#19](https://github.com/alrayyes/hush-hush-action/issues/19)) ([89fd325](https://github.com/alrayyes/hush-hush-action/commit/89fd32546c65d49736c657d6d154cf11acdb2233))

## [1.2.0](https://github.com/alrayyes/hush-hush-action/compare/v1.1.0...v1.2.0) (2026-09-10)


### Features

* wire LTeX and Vale prose linting ([#15](https://github.com/alrayyes/hush-hush-action/issues/15)) ([b1fde55](https://github.com/alrayyes/hush-hush-action/commit/b1fde559f84aea313c39ea23f290d7d0d465a356))


### Bug Fixes

* **ci:** report_type is underscore-separated, not report-type ([#17](https://github.com/alrayyes/hush-hush-action/issues/17)) ([e4418b4](https://github.com/alrayyes/hush-hush-action/commit/e4418b4ae1dd85cd6b493c0709a6ca0e3f26b639))

## [1.1.0](https://github.com/alrayyes/hush-hush-action/compare/v1.0.0...v1.1.0) (2026-09-10)


### Features

* add Codecov Test Analytics ([#14](https://github.com/alrayyes/hush-hush-action/issues/14)) ([a1da6da](https://github.com/alrayyes/hush-hush-action/commit/a1da6dad760b928d949e7f5ffdd9c7b3196a7b5d)), closes [#7](https://github.com/alrayyes/hush-hush-action/issues/7)
* wire code coverage for the bash test suite ([#12](https://github.com/alrayyes/hush-hush-action/issues/12)) ([527cb9f](https://github.com/alrayyes/hush-hush-action/commit/527cb9f3f2b4468f138cbbbb55cd966f0ec80bb6)), closes [#6](https://github.com/alrayyes/hush-hush-action/issues/6)

## 1.0.0 (2026-09-10)


### Features

* fetch and mask a secret from hush-hush ([f034fdb](https://github.com/alrayyes/hush-hush-action/commit/f034fdb03aaa7e48708f95a82922f303612a2b8c))
* fetch and mask a secret from hush-hush ([f574e8a](https://github.com/alrayyes/hush-hush-action/commit/f574e8a4b7cdcd0a622a5b02485d1eb2fcd7d8f5)), closes [#2](https://github.com/alrayyes/hush-hush-action/issues/2)


### Bug Fixes

* **ci:** use RELEASE_TOKEN for release-please, not GITHUB_TOKEN ([#10](https://github.com/alrayyes/hush-hush-action/issues/10)) ([f7bf811](https://github.com/alrayyes/hush-hush-action/commit/f7bf8115d5dda98a4b2bfbb3338f4bec126d6058))

# Changelog

All notable changes to this project will be documented in this file.

## [0.5.1](https://github.com/altertable-ai/altertable-lakehouse-ruby/compare/altertable-lakehouse/v0.5.0...altertable-lakehouse/v0.5.1) (2026-05-29)


### Bug Fixes

* **array payload:** ensure array payload are also converted to JSON ([#39](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/39)) ([0d01361](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/0d013615f44104890f482c20da9316b9f8a7fee4))

## [0.5.0](https://github.com/altertable-ai/altertable-lakehouse-ruby/compare/altertable-lakehouse/v0.4.2...altertable-lakehouse/v0.5.0) (2026-05-28)


### Features

* add optional headers to all methods ([#37](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/37)) ([34e3c2d](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/34e3c2d943742a5f2a3f6a309154a8ee9aa84dc7))

## [0.4.2](https://github.com/altertable-ai/altertable-lakehouse-ruby/compare/altertable-lakehouse/v0.4.1...altertable-lakehouse/v0.4.2) (2026-05-27)


### Bug Fixes

* **rbi:** fix more RBI signatures ([#35](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/35)) ([8be797c](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/8be797c813a9295795c1aedd9bc1c1d186b1e4cc))

## [0.4.1](https://github.com/altertable-ai/altertable-lakehouse-ruby/compare/altertable-lakehouse/v0.4.0...altertable-lakehouse/v0.4.1) (2026-05-27)


### Bug Fixes

* **rbi:** rework RBI syntax & nested types ([#33](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/33)) ([4845ab1](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/4845ab1dbb1bfbac04eb4629b0f81ce0e4422e0d))

## [0.4.0](https://github.com/altertable-ai/altertable-lakehouse-ruby/compare/altertable-lakehouse/v0.3.0...altertable-lakehouse/v0.4.0) (2026-05-27)


### Features

* add v0.11.0 lakehouse operations ([#27](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/27)) ([cc52dbb](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/cc52dbb4ef995b027697f6fa68164f6704e02058))
* **explain:** add /explain support ([#31](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/31)) ([b326e94](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/b326e949742f9f4c89e5ea2aeb67028513e8a118))
* **typings:** add RBI & RBS typings ([#29](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/29)) ([c569e6d](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/c569e6d58c1c36af2f51a329591eebd2e0677d17))

## [0.3.0](https://github.com/altertable-ai/altertable-lakehouse-ruby/compare/altertable-lakehouse-v0.2.0...altertable-lakehouse/v0.3.0) (2026-03-08)


### Features

* bootstrap initial SDK based on specs v0.1.0 ([#2](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/2)) ([7bfca30](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/7bfca30d2f1db4d1892eb75f819343c9922962c7))
* optional http client (faraday/httpx/net-http) with adapter pattern ([#15](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/15)) ([8189d9f](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/8189d9f5313d1728ece0ec58f09c74d9e0e61e5a))
* update SDK to specs v0.3.0 ([#5](https://github.com/altertable-ai/altertable-lakehouse-ruby/issues/5)) ([23e3a55](https://github.com/altertable-ai/altertable-lakehouse-ruby/commit/23e3a5507347c66616f995710392de3e2690eb78))

## [Unreleased]

### Changed
- **BREAKING**: Removed per-request credential overrides from all client methods to comply with v0.3.0 specs. Authentication must now be configured at initialization time.

## [0.2.0] - 2026-03-04

### Changed
- **BREAKING**: Replaced Bearer token authentication with HTTP Basic Auth.
- **BREAKING**: Removed `api_key` argument from `Altertable::Lakehouse::Client.new`.
- Added support for `username`/`password` and `basic_auth_token` in client initialization.
- Added environment variable support for `ALTERTABLE_USERNAME`, `ALTERTABLE_PASSWORD`, and `ALTERTABLE_BASIC_AUTH_TOKEN`.
- Updated streaming query parsing to raise `ParseError` on malformed JSON lines instead of silently ignoring them.

## [0.1.0] - 2026-03-04

### Added
- Initial implementation of Altertable Lakehouse Ruby Client.
- Support for `append`, `query` (streamed/accumulated), `upsert`, `validate`.
- Support for `get_query`, `cancel_query`.
- Typed request/response models.
- Faraday-based HTTP client with retries.

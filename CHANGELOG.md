# Changelog

All notable changes to this project will be documented in this file.

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
- Support for `append`, `query` (streamed/accumulated), `upload`, `validate`.
- Support for `get_query`, `cancel_query`.
- Typed request/response models.
- Faraday-based HTTP client with retries.

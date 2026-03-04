# Changelog

All notable changes to this project will be documented in this file.

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

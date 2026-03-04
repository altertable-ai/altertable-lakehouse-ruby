# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- **BREAKING**: Replaced Bearer token authentication with HTTP Basic Auth.
- **BREAKING**: Removed `api_key` argument from `Altertable::Lakehouse::Client.new`.
- Added support for `username`/`password` and `basic_auth_token` in client initialization.
- Added environment variable support for `ALTERTABLE_USERNAME`, `ALTERTABLE_PASSWORD`, and `ALTERTABLE_BASIC_AUTH_TOKEN`.
- Added support for per-request credential overrides.
- Updated streaming query parsing to raise `ParseError` on malformed JSON lines instead of silently ignoring them.

## [0.1.0] - 2026-03-04

### Added
- Initial implementation of Altertable Lakehouse Ruby Client.
- Support for `append`, `query` (streamed/accumulated), `upload`, `validate`.
- Support for `get_query`, `cancel_query`.
- Typed request/response models.
- Faraday-based HTTP client with retries.

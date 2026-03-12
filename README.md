# Altertable Lakehouse Ruby SDK

You can use this SDK to query and ingest data in Altertable Lakehouse from Ruby applications.

## Install

```bash
gem install altertable-lakehouse
```

## Quick start

```ruby
require "altertable/lakehouse"

client = Altertable::Lakehouse::Client.new(
  username: "your_username",
  password: "your_password"
)

result = client.query_all(statement: "SELECT 1 AS ok")
puts result[:rows]
```

## API reference

### Initialization

`Altertable::Lakehouse::Client.new(**options)`

Creates a client authenticated with Basic Auth credentials or token.

### `append`

`append(catalog:, schema:, table:, payload:, **options)` appends one or more rows.

### `query_all`

`query_all(statement:, **options)` executes a SQL query and returns all rows in memory.

### `query`

`query(statement:, **options)` executes a SQL query and streams rows.

### `upload`

`upload(catalog:, schema:, table:, format:, mode:, file_io:, **options)` uploads a file.

### `get_query`

`get_query(query_id)` returns query execution details.

### `cancel_query`

`cancel_query(query_id, session_id:)` cancels an in-flight query.

### `validate`

`validate(statement:)` validates SQL without execution.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `username` | `String` | `ENV["ALTERTABLE_USERNAME"]` | Basic Auth username. |
| `password` | `String` | `ENV["ALTERTABLE_PASSWORD"]` | Basic Auth password. |
| `basic_auth_token` | `String` | `ENV["ALTERTABLE_BASIC_AUTH_TOKEN"]` | Base64 `username:password` token. |
| `base_url` | `String` | `"https://api.altertable.ai"` | API base URL. |
| `timeout` | `Integer` | `10` | Request timeout in seconds. |
| `user_agent` | `String \| nil` | `nil` | Optional user-agent suffix. |

## Development

Prerequisites: Ruby 3.1+ and Bundler.

```bash
bundle install
bundle exec rake spec
bundle exec rubocop
```

## License

See [LICENSE](LICENSE).
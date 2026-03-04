# Altertable Lakehouse Ruby Client

Official Ruby client for the [Altertable Lakehouse API](https://api.altertable.ai).

## Installation

Add to your Gemfile:

```ruby
gem 'altertable-lakehouse'
```

And run:

    $ bundle install

Or install it yourself as:

    $ gem install altertable-lakehouse

## Quick Start

```ruby
require "altertable/lakehouse"

# Initialize with credentials
client = Altertable::Lakehouse::Client.new(
  username: "your_username",
  password: "your_password"
)

# Append a row
client.append(
  catalog: "main",
  schema: "public",
  table: "events",
  payload: { user_id: 123, event: "signup", timestamp: Time.now.iso8601 }
)

# Query data
result = client.query_all(
  statement: "SELECT * FROM main.public.events LIMIT 10"
)
result[:rows].each { |row| puts row }
```

## API Reference

### Initialization

Supports Basic Authentication via username/password or pre-encoded token.

```ruby
# 1. Username/Password
client = Altertable::Lakehouse::Client.new(
  username: "your_username",
  password: "your_password",
  base_url: "https://api.altertable.ai", # Optional
  timeout: 10 # Optional
)

# 2. Pre-encoded Basic Auth Token
client = Altertable::Lakehouse::Client.new(
  basic_auth_token: "dXNlcm5hbWU6cGFzc3dvcmQ=" # base64(username:password)
)

# 3. Environment Variables
# Set ALTERTABLE_USERNAME and ALTERTABLE_PASSWORD
# OR set ALTERTABLE_BASIC_AUTH_TOKEN
client = Altertable::Lakehouse::Client.new
```

### `append`

Appends one or more rows to a table.

```ruby
# Single row
client.append(
  catalog: "main",
  schema: "public",
  table: "events",
  payload: { user_id: 123, event: "signup" }
)

# Batch append
client.append(
  catalog: "main",
  schema: "public",
  table: "events",
  payload: [
    { user_id: 123, event: "click" },
    { user_id: 456, event: "view" }
  ]
)

# Override credentials per-request
client.append(
  catalog: "main",
  schema: "public",
  table: "events",
  payload: { user_id: 789 },
  username: "other_user",
  password: "other_password"
)
```

### `query_all`

Executes a SQL query and returns all rows in memory (accumulated).

```ruby
result = client.query_all(
  statement: "SELECT * FROM main.public.events LIMIT 10"
)

puts result[:metadata] # Hash
puts result[:columns]  # Array of columns
result[:rows].each do |row|
  puts row
end
```

### `query` (Streaming)

Executes a SQL query and streams rows efficiently for large result sets.

```ruby
result = client.query(
  statement: "SELECT * FROM main.public.events"
)

# Note: metadata/columns are available after iteration starts
result.each do |row|
  puts row
end
```

### `upload`

Uploads a file (CSV, Parquet, etc.) to a table.

```ruby
File.open("data.csv", "rb") do |file|
  client.upload(
    catalog: "main",
    schema: "public",
    table: "events",
    format: "csv",
    mode: "append",
    file_io: file
  )
end
```

### `get_query`

Retrieves information about a query execution.

```ruby
info = client.get_query("query-uuid")
puts info.state # e.g. "RUNNING", "COMPLETED"
```

### `cancel_query`

Cancels a running query.

```ruby
client.cancel_query("query-uuid", session_id: "session-123")
```

### `validate`

Validates a SQL statement without executing it.

```ruby
resp = client.validate(statement: "SELECT * FROM invalid_table")
puts resp.valid # => false
puts resp.error
```

## Configuration

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `username` | String | `ENV["ALTERTABLE_USERNAME"]` | Basic Auth username |
| `password` | String | `ENV["ALTERTABLE_PASSWORD"]` | Basic Auth password |
| `basic_auth_token` | String | `ENV["ALTERTABLE_BASIC_AUTH_TOKEN"]` | Pre-encoded Basic Auth token |
| `base_url` | String | `https://api.altertable.ai` | API base URL |
| `timeout` | Integer | `10` | Request timeout in seconds |
| `user_agent` | String | `nil` | Custom User-Agent suffix |

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

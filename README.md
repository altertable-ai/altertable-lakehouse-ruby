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

## Usage

### Configuration

Supports Basic Authentication via username/password or pre-encoded token.

```ruby
require "altertable/lakehouse"

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

### Append Data

```ruby
client.append(
  catalog: "main",
  schema: "public",
  table: "events",
  payload: { user_id: 123, event: "signup", timestamp: Time.now.iso8601 }
)

# Batch append:
client.append(
  catalog: "main",
  schema: "public",
  table: "events",
  payload: [
    { user_id: 123, event: "click" },
    { user_id: 456, event: "view" }
  ]
)
```

### Query Data (Accumulated)

Fetch all rows at once:

```ruby
result = client.query_all(
  statement: "SELECT * FROM main.public.events LIMIT 10"
)

puts result[:metadata]
puts result[:columns]
result[:rows].each do |row|
  puts row
end
```

### Query Data (Streamed)

Stream rows efficiently for large result sets:

```ruby
result = client.query(
  statement: "SELECT * FROM main.public.events"
)

# Note: metadata/columns are available after iteration starts
result.each do |row|
  puts row
end
```

### Upload File

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

### Manage Queries

```ruby
# Get query info
info = client.get_query("query-uuid")

# Cancel running query
client.cancel_query("query-uuid", session_id: "session-123")
```

### Validate SQL

```ruby
resp = client.validate(statement: "SELECT * FROM invalid_table")
puts resp.valid # => false
puts resp.error
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

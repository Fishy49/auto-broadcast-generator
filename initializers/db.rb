# frozen_string_literal: true

DB = Sequel.connect(
  ENV.fetch('DATABASE_CONNECTION_STRING', 'sqlite://db.sqlite3'),
  timeout: 20_000
)

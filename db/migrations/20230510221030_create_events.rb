# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:events) do
      primary_key :id
      Time :created_at, null: false
      String :source, null: false
      String :event_text, null: false, text: true
      String :raw_source, null: true, text: true
    end
  end

  down do
    drop_table(:events)
  end
end

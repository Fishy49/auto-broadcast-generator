# frozen_string_literal: true

Sequel.migration do
  change do
    add_column :events, :is_archived, TrueClass, default: false
  end
end

# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:config) do
      String :key, null: false, primary_key: true
      String :value, text: true
    end
  end

  down do
    drop_table(:config)
  end
end

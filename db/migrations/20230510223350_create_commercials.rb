# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:commercials) do
      primary_key :id
      Time :created_at
      String :script, text: true
      String :music_file
      String :audio_file
      Integer :length
    end
  end

  down do
    drop_table(:commercials)
  end
end

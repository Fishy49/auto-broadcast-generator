# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:broadcasts) do
      primary_key :id
      foreign_key :broadcast_generation_job_id, :broadcast_generation_jobs
      Time :created_at
      String :prompt, text: true
      String :script, text: true
      String :audio_file
      Integer :length
      Time :broadcast_at
      Time :archived_at
    end
  end

  down do
    drop_table(:broadcasts)
  end
end

# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:broadcast_generation_job_logs) do
      primary_key :id
      foreign_key :broadcast_generation_job_id, :broadcast_generation_jobs
      Time :created_at
      String :log_level
      String :step
      String :message, text: true
    end
  end

  down do
    drop_table(:broadcast_generation_job_logs)
  end
end

# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:broadcast_generation_jobs) do
      primary_key :id
      Time :started_at
      Time :finished_at
      String :completed_status
      String :current_step
      Time :script_started_at
      Time :script_finished_at
      Time :vocals_started_at
      Time :vocals_finished_at
      Time :mixing_started_at
      Time :mixing_finished_at
    end
  end

  down do
    drop_table(:broadcast_generation_jobs)
  end
end

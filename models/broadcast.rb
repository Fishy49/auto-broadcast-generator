# frozen_string_literal: true

# Handles generation of a broadcast
class Broadcast < Sequel::Model
  many_to_one :broadcast_generation_job

  dataset_module do
    def latest
      order(Sequel.desc(:id))
    end
  end

  def current_step
    broadcast_generation_job.current_step
  end

  def status
    broadcast_generation_job.completed_status
  end

  def self.last_broadcast_date
    latest_broadcast = Broadcast.last
    return 1.hour.ago if latest_broadcast.nil?

    latest_broadcast.created_at
  end
end

# frozen_string_literal: true

# Log messages for broadcast generation
class BroadcastGenerationJobLog < Sequel::Model
  many_to_one :broadcast_generation_job
end

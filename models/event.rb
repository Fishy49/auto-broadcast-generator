# frozen_string_literal: true

# Represents an event to be included in the broadcast
class Event < Sequel::Model
  dataset_module do
    def active
      where(is_archived: false)
    end

    def latest
      order(Sequel.desc(:id))
    end

    def latest_weather
      where(source: 'weather').latest
    end
  end
end

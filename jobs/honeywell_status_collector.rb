# frozen_string_literal: true

# Wrapper for getting Honeywell (thermostat) Status
class HoneywellStatusCollector
  def initialize(logger = nil)
    @logger = Logger.new($stdout) if logger.nil?
    @status = JSON.parse(`python3 get_honeywell_status.py`)
  end

  def save_status_as_event
    Event.create(
      created_at: Time.now,
      source: 'honeywell',
      event_text: event_text(@status),
      raw_source: @status.to_json
    )
  end

  def event_text(status)
    "The thermostat is set to #{status['mode']} and the indoor temperature is #{status['temperature']}"
  end
end

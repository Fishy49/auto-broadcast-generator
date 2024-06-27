# frozen_string_literal: true

# Wrapper for getting Wyze Event Collector
class WyzeEventCollector
  def initialize(logger = nil)
    @logger = Logger.new($stdout) if logger.nil?
    @events = JSON.parse(`python3 get_wyze_events.py`)
  end

  def save_events
    @events.each do |event|
      Event.create(
        created_at: DateTime.strptime(event['time'].to_s, '%Q').to_time.localtime,
        source: 'wyze',
        event_text: event_text(event),
        raw_source: event.to_json
      )
    end
  end

  def event_text(event)
    str = "#{event['camera_name']} detected #{event['alarm_type']}"
    if event['tags'].count > 0
      verb = event['alarm_type'].downcase == 'sound' ? 'heard' : 'saw'
      str = "#{str} and #{verb} #{event['tags'].map { |t| "a #{t}" }.join(' and ')}"
    end
    str
  end
end

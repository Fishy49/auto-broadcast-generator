# frozen_string_literal: true

require 'googleauth'
require 'google/cloud/pubsub'
require 'logger'

# Wrapper for getting Google Cloud Events
class GoogleEventCollector
  TOPIC = ENV.fetch('GOOGLE_PUBSUB_TOPIC', nil)

  attr_accessor :pubsub

  def initialize
    @pubsub = Google::Cloud::PubSub.new(
      project_id: ENV.fetch('GOOGLE_PUBSUB_PROJECT_ID', nil),
      credentials: ENV.fetch('GOOGLE_PUBSUB_SERVICE_ACCOUNT_CREDENTIAL_FILE', nil)
    )
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.listen(logger = nil)
    return if File.exist?('google_event.lock')

    FileUtils.touch('google_event.lock')

    logger = Logger.new($stdout) if logger.nil?

    @gd = GoogleDevices.new
    events = GoogleEventCollector.new
    events.pubsub.topic GoogleEventCollector::TOPIC
    sub = events.pubsub.subscription ENV.fetch('GOOGLE_PUBSUB_SUBSCRIPTION_NAME', nil)

    subscriber = sub.listen threads: { callback: 1 } do |received_message|
      logger.debug('Received Message')

      Event.create(
        created_at: received_message.message.published_at.to_i,
        source: 'google',
        event_text: parse_to_event_string(received_message.message.data),
        raw_source: received_message.message.data
      )
      received_message.acknowledge!
    end

    subscriber.on_error do |exception|
      logger.debug "Exception: #{exception.class} #{exception.message}"
    end

    at_exit do
      subscriber.stop!(10)
      FileUtils.rm_f('google_event.lock')
    end

    subscriber.start
  ensure
    FileUtils.rm_f('google_event.lock')
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def self.parse_to_event_string(data)
    event = JSON.parse(data.to_s)
    update = event['resourceUpdate']

    device_info = get_device_info(update)
    event_type = get_event_type(update)

    case event_type
    when 'sdm.devices.traits.Temperature'
      event_text = temperature_event_text(device_info, update, event_type)
    when 'sdm.devices.events.CameraPerson.Person'
      event_text = "#{device_info} saw a person"
    when 'sdm.devices.traits.Humidity'
      event_text = humidity_event_text(device_info, update, event_type)
    when 'sdm.devices.traits.Fan'
      event_text = fan_event_text(device_info, update, event_type)
    when 'sdm.devices.traits.ThermostatHvac'
      event_text = hvac_event_text(device_info, update, event_type)
    when 'sdm.devices.events.CameraMotion.Motion'
      event_text = "#{device_info} saw some motion"
    end

    "#{event_text} at #{event['timestamp']}"
  end
  # rubocop:enable Metrics/MethodLength

  def self.get_device_info(update)
    device_name = @gd.device_names.find { |d| d[:name] == update['name'] }[:title]
    device_type = @gd.device_names.find { |d| d[:name] == update['name'] }[:type]
    device_type = '' if device_name == device_type
    "The #{device_name} #{device_type}"
  end

  def self.get_event_type(update)
    update['traits'].nil? ? update['events'].keys.first : update['traits'].keys.first
  end

  def self.temperature_event_text(device_info, update, event_type)
    temp = c_to_f(update['traits'][event_type]['ambientTemperatureCelsius'])
    "#{device_info} temperature was reported as #{temp}"
  end

  def self.humidity_event_text(device_info, update, event_type)
    humidity = update['traits'][event_type]['ambientHumidityPercent']
    "#{device_info} Humidity was reported as #{humidity} percent"
  end

  def self.fan_event_text(device_info, update, event_type)
    "#{device_info} Fan was set to #{update['traits'][event_type]['status']}"
  end

  def self.hvac_event_text(device_info, update, event_type)
    "#{device_info} HVAC was set to #{update['traits'][event_type]['status']}"
  end

  def self.c_to_f(celcius)
    (celcius * 9 / 5) + 32
  end
end

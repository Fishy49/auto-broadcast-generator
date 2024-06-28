# frozen_string_literal: true

require 'active_support/time' # Allow numeric durations (eg: 1.minutes)
require 'bundler/setup'
require 'clockwork'
require 'dotenv/load'
require 'logger'
require 'securerandom'
require 'sequel'
require 'taglib'
require 'tokenizers'

Dir[
  './initializers/*.rb',
  './lib/*.rb',
  './models/*.rb',
  './jobs/*.rb'
].each { |file| require file }

Bundler.require

DB.loggers << Logger.new($stdout)

LOGGER = Logger.new('log.txt')
CONFIG = Config.new(DB)

# Handles regular generation of radio broadcasts
module Clockwork
  handler do |job|
    Thread.new do
      case job
      when 'generate_broadcast'
        BroadcastGenerationJob.generate(LOGGER)
      when 'collect_weather'
        collector = OpenWeatherCollector.new(LOGGER)
        collector.save_event
      when 'collect_emails'
        collector = EmailCollector.new(LOGGER)
        collector.save_events
      when 'collect_wyze_events'
        collector = WyzeEventCollector.new(LOGGER)
        collector.save_events
      when 'collect_honeywell_status'
        collector = HoneywellStatusCollector.new(LOGGER)
        collector.save_status_as_event
      end
    end
  end

  every(1.hour, 'generate_broadcast', if: ->(t) { t.hour == 20 })

  every(4.hours, 'collect_weather')

  every(4.hours, 'collect_honeywell_status')

  every(30.minutes, 'collect_emails')

  every(2.hours, 'collect_wyze_events')
end

# frozen_string_literal: true

require 'active_support/core_ext/integer/inflections'
require 'logger'

# Wrapper for getting OpenWeatherMap Forecastss
class OpenWeatherCollector
  attr_reader :data

  def initialize(logger = nil)
    @logger = Logger.new($stdout) if logger.nil?
    base_url = 'https://api.openweathermap.org/data/3.0/onecall'

    options = { query: {
      lat: CONFIG.weather_lat,
      lon: CONFIG.weather_lon,
      appid: CONFIG.openweathermap_api_key,
      units: 'imperial', exclude: 'minutely,hourly'
    } }

    @data = HTTParty.get(base_url, options)
  end

  def save_event
    Event.create(
      created_at: Time.now,
      source: 'weather',
      event_text: forecast_text,
      raw_source: @data.to_json
    )
  end

  private

    def current
      @data['current']
    end

    def today
      @data['daily'][0]
    end

    def tomorrow
      @data['daily'][1]
    end

    # rubocop:disable Metrics/AbcSize
    def forecast_text
      [
        'Today,',
        to_date_string(Time.at(current['dt'])),
        "#{today['summary']}.",
        "Right now it's #{current['temp'].round} and feels like #{current['feels_like'].round}",
        "with a low of #{today['temp']['min'].round}",
        "with a high of #{today['temp']['max'].round}.",
        "Tomorrow, #{tomorrow['summary']}",
        "and a high of #{tomorrow['temp']['max'].round} and a head index of #{tomorrow['feels_like']['day'].round}"
      ].join(' ').gsub('cloudy', 'cloudy skies')
    end
    # rubocop:enable Metrics/AbcSize

    def to_date_string(time)
      time.strftime("%A, %B the #{time.day.ordinalize}")
    end
end

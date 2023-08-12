# frozen_string_literal: true

# Wrapper for getting key/value pairs from the config table
class Config
  CONFIG_VARS = %i[
    station_name
    station_frequency
    station_era
    broadcaster_name
    openai_access_token
    openai_organization_id
    elevenlabs_api_key
    elevenlabs_voice_id
    openweathermap_api_key
    weather_lat
    weather_lon
    imap_host
    imap_port
    imap_login
    imap_password
    imap_search_terms
  ].freeze

  attr_accessor :db

  def initialize(db)
    @db = db[:config]
    results = @db.where(key: CONFIG_VARS.map(&:to_s)).all
    CONFIG_VARS.each do |var|
      result = results.find { |r| r[:key] == var.to_s }
      value = result.nil? ? nil : result[:value]
      instance_variable_set("@#{var}", value)
    end
  end

  CONFIG_VARS.each do |var|
    define_method(var.to_s) do
      instance_variable_get("@#{var}")
    end

    define_method("#{var}=") do |value|
      @db.insert_conflict(target: :key, update: { value: Sequel[:excluded][:value] })
         .insert(key: var.to_s, value:)
      instance_variable_set("@#{var}", value)
      value
    end
  end
end

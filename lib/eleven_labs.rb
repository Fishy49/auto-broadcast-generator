# frozen_string_literal: true

require 'httparty'

# Wrapper for getting Eleven Labs text-to-speech
class ElevenLabs
  BASE_URL = 'https://api.elevenlabs.io/v1'

  def self.voices
    r = make_request(url: '/voices', method: :get)
    r['voices']
  end

  def self.tts(voice_id, text, filename)
    File.open(filename, 'w') do |file|
      HTTParty.post(
        "#{BASE_URL}/text-to-speech/#{voice_id}/stream",
        headers: download_headers, body: { text:, model_id: 'eleven_monolingual_v2' }.to_json, stream_body: true
      ) do |fragment|
        raise StandardError, "Non-success status code while streaming #{fragment.code}" unless fragment.code == 200

        file.write(fragment)
      end
    end
    filename
  end

  def self.make_request(url:, method:, query: {}, headers: {}, body: {})
    HTTParty.send(method,
                  "#{BASE_URL}#{url}",
                  query:,
                  headers: default_headers.merge(headers),
                  body:)
  end

  def self.default_headers
    {
      'Accept' => 'application/json',
      'xi-api-key' => CONFIG.elevenlabs_api_key
    }
  end

  def self.download_headers
    default_headers.merge(
      {
        'Content-Type' => 'application/json',
        'Accept' => 'audio/mpeg'
      }
    )
  end

  def self.unique_filename
    SecureRandom.uuid
  end
end

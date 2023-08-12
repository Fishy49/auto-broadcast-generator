# frozen_string_literal: true

# Wrapper for Calling sox
class AudioMixer
  WORKING_DIR = 'work'
  INTRO_FILE = "#{WORKING_DIR}/intro.mp3".freeze
  OUTRO_FILE = "#{WORKING_DIR}/outro.mp3".freeze

  PADDED_VOCALS_FILE = "#{WORKING_DIR}/padded_vocals.mp3".freeze
  PADDED_OUTRO_FILE = "#{WORKING_DIR}/padded_outro.mp3".freeze
  FADED_OUTRO_FILE = "#{WORKING_DIR}/faded_outro.mp3".freeze

  MIXED_BROADCAST_FILE = "#{WORKING_DIR}/mixed_broadcast.wav".freeze
  COMPRESSED_BROADCAST_FILE = "#{WORKING_DIR}/compressed_broadcast.wav".freeze

  OUTPUT_FOLDER = 'broadcast_audio'

  attr_accessor :vocals_file, :intro_length, :outro_length, :vocals_length, :final_file, :final_length

  def initialize(vocals_file)
    @vocals_file = vocals_file
    @vocals_length = file_length(@vocals_file)
    @intro_length = file_length(INTRO_FILE)
    @outro_length = file_length(OUTRO_FILE)
  end

  def mix
    # rubocop:disable Layout/LineLength
    # pad vocals
    system("sox #{@vocals_file} #{PADDED_VOCALS_FILE} pad 5@0")
    # pad outro
    system("sox #{OUTRO_FILE} #{PADDED_OUTRO_FILE} pad #{@vocals_length - 5}@0")
    # fade outro
    system("sox #{PADDED_OUTRO_FILE} #{FADED_OUTRO_FILE} fade 0 #{@vocals_length + @outro_length - 15} 5")
    # mix files
    system("sox -M -v 0.5 #{INTRO_FILE} -v 1.2 #{PADDED_VOCALS_FILE} -v 0.5 #{FADED_OUTRO_FILE} #{MIXED_BROADCAST_FILE}")
    # compress and fade in
    system("sox #{MIXED_BROADCAST_FILE} #{COMPRESSED_BROADCAST_FILE} fade 5 compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 norm -3")
    # rubocop:enable Layout/LineLength

    # wav to mono mp3
    @final_file = "#{OUTPUT_FOLDER}/#{SecureRandom.uuid}.mp3"
    system("sox #{COMPRESSED_BROADCAST_FILE} #{@final_file} remix -")

    @final_length = file_length(@final_file)
  ensure
    cleanup
  end

  private

    def file_length(file_path)
      length = 0
      return length unless File.exist?(file_path)

      TagLib::MPEG::File.open(file_path) do |file|
        length = file.audio_properties.length_in_seconds
      end
      length
    end

    def cleanup
      [
        PADDED_VOCALS_FILE,
        PADDED_OUTRO_FILE,
        FADED_OUTRO_FILE,
        MIXED_BROADCAST_FILE,
        COMPRESSED_BROADCAST_FILE,
        @vocals_file
      ].each do |file|
        FileUtils.rm_f(file)
      end
    end
end

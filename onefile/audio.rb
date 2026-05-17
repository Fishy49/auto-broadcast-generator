require 'taglib'

def audio_length_in_seconds(file_path)
  length = 0
  return length unless File.exist?(file_path)

  TagLib::MPEG::File.open(file_path) do |file|
    length = file.audio_properties.length_in_seconds
  end
  length
end

def mix_broadcast_audio(vocals_file, output_file)
	original_intro_outro_file = "radio_intro_outro.mp3"
	intro_outro_file = "radio_intro_outro_resampled.mp3"
    vocals_length = audio_length_in_seconds(vocals_file)
    intro_outro_length = audio_length_in_seconds(intro_outro_file)

    working_dir = 'work'
    padded_vocals_file = "#{working_dir}/padded_vocals.mp3".freeze
    faded_intro_outro_file = "#{working_dir}/faded_intro_outro.mp3"
	padded_outro_file = "#{working_dir}/padded_outro.mp3".freeze
	mixed_broadcast_file = "#{working_dir}/mixed_broadcast.wav".freeze
	compressed_broadcast_file = "#{working_dir}/compressed_broadcast.wav".freeze

	system("mkdir work")
	system("rm #{output_file}")

	# resample file from Udio
	system("sox #{original_intro_outro_file} #{intro_outro_file} rate -h 44100")

	# pad vocals
    system("sox #{vocals_file} #{padded_vocals_file} pad 10@0")
    # fade intro outro
    system("sox #{intro_outro_file} #{faded_intro_outro_file} fade 5 25 20")
    # pad outro
    system("sox #{faded_intro_outro_file} #{padded_outro_file} pad #{vocals_length}@0")
    # mix files
    system("sox -M -v 0.3 #{faded_intro_outro_file} -v 1.2 #{padded_vocals_file} -v 0.4 #{padded_outro_file} #{mixed_broadcast_file}")
    # compress and fade in
    system("sox #{mixed_broadcast_file} #{compressed_broadcast_file} fade 5 compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 norm -3")
    # rubocop:enable Layout/LineLength

    # wav to mono mp3
    system("sox #{compressed_broadcast_file} #{output_file} remix -")

    system("rm -rf work")
end

mix_broadcast_audio("vocals_file.mp3", "broadcast.mp3")
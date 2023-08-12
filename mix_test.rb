# frozen_string_literal: true

require 'fileutils'
require 'securerandom'
require 'taglib'

vocals_length = 0
TagLib::MPEG::File.open('work/sample_vocals.mp3') do |file|
  vocals_length = file.audio_properties.length_in_seconds
end

intro_outro_length = 0
TagLib::MPEG::File.open('work/introoutro.mp3') do |file|
  intro_outro_length = file.audio_properties.length_in_seconds
end

# rubocop:disable Layout/LineLength
# pad vocals
puts "Running 'sox work/sample_vocals.mp3 work/padded_vocals.mp3 pad 5@0'"
system('sox work/sample_vocals.mp3 work/padded_vocals.mp3 pad 5@0')
puts 'Finished'
# pad outro
puts "Running sox 'work/introoutro.mp3 work/padded_outro.mp3 pad #{vocals_length - 5}@0'"
system("sox work/introoutro.mp3 work/padded_outro.mp3 pad #{vocals_length - 5}@0")
puts 'Finished'
# fade outro
puts "Running sox 'work/padded_outro.mp3 work/faded_outro.mp3 fade 0 #{vocals_length + intro_outro_length - 15} 5'"
system("sox work/padded_outro.mp3 work/faded_outro.mp3 fade 0 #{vocals_length + intro_outro_length - 15} 5")
puts 'Finished'
# mix files
puts "Running 'sox -M -v 0.5 work/introoutro.mp3 -v 1.2 work/padded_vocals.mp3 -v 0.5 work/faded_outro.mp3 work/mixed_broadcast.wav'"
system('sox -M -v 0.5 work/introoutro.mp3 -v 1.2 work/padded_vocals.mp3 -v 0.5 work/faded_outro.mp3 work/mixed_broadcast.wav')
puts 'Finished'
# compress
puts "Running 'sox work/mixed_broadcast.wav work/compressed_broadcast.wav fade 5 compand 0.3,1 6:-70,-60,-20 -5 -90 0.2'"
system('sox work/mixed_broadcast.wav work/compressed_broadcast.wav fade 5 compand 0.3,1 6:-70,-60,-20 -5 -90 0.2')
puts 'Finished'
# rubocop:enable Layout/LineLength

# mp3
filename = "#{SecureRandom.uuid}.mp3"
puts "Running 'sox work/compressed_broadcast.wav broadcast_audio/#{filename} remix -'"
system("sox work/compressed_broadcast.wav broadcast_audio/#{filename} remix -")
puts 'Finished'

mixed_length = 0
TagLib::MPEG::File.open("broadcast_audio/#{filename}") do |file|
  mixed_length = file.audio_properties.length_in_seconds
end

puts 'Cleaning files up'
['work/padded_vocals.mp3', 'work/padded_outro.mp3', 'work/faded_outro.mp3', 'work/mixed_broadcast.wav',
 'work/compressed_broadcast.wav'].each do |file|
  FileUtils.rm(file)
end
puts 'Finished'

puts "Length of broadcast_audio/#{filename} is #{mixed_length} seconds"

system("play broadcast_audio/#{filename}")

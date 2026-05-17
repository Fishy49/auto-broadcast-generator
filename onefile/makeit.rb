require 'json'

class Broadcast < Struct.new(:created_at, :events, :script_prompt, :script, :audio_file, :error)
  FILE_PATH = 'broadcast.json'

  def initialize(created_at: '', events: [], script_prompt: '', script: '', audio_file: '', error: '')
    super(created_at, events, script_prompt, script, audio_file, error)
  end
  
  def self.load
    return new unless File.exist?(FILE_PATH)
    
    data = JSON.parse(File.read(FILE_PATH))
    new(**data.transform_keys(&:to_sym))
  rescue JSON::ParserError
    new
  end
  
  def save
    File.write(FILE_PATH, JSON.pretty_generate(to_h))
    self
  end
  
  def to_h
    super.transform_keys(&:to_s)
  end
end
# frozen_string_literal: true

# Handles generation of a broadcast
class BroadcastGenerationJob < Sequel::Model
  one_to_one :broadcast
  one_to_many :broadcast_generation_job_logs

  attr_accessor :logger

  def self.generate(logger)
    existing_job = BroadcastGenerationJob.where(finished_at: nil).exclude(started_at: nil).first

    unless existing_job.nil?
      logger.info("BroadcastGenerationJob #{existing_job.id} already running. Exiting.")
      return
    end

    logger.info('Starting BroadcastGenerationJob')
    job = BroadcastGenerationJob.create(started_at: Time.now, current_step: :prompt)
    job.logger = logger
    job.broadcast = Broadcast.create(created_at: Time.now)

    job.generate!
  end

  # rubocop:disable Metrics/MethodLength
  def generate!
    do_prompt!
    do_script!
    do_vocals!
    do_mixing!
    update(current_step: :finished, completed_status: :success, finished_at: Time.now)
    DB['UPDATE events SET is_archived = true WHERE source <> \'weather\' AND id IN ?', @events.map(&:id)].update
    log('Generation complete')
  rescue StandardError => e
    log("ERROR! - #{e.message}", 'error')
    update(current_step: :finished, completed_status: :error, finished_at: Time.now)
    raise e
  end
  # rubocop:enable Metrics/MethodLength

  private

    def log(message, level = 'info')
      logger.public_send(level.to_sym, message)
      BroadcastGenerationJobLog.create(
        broadcast_generation_job_id: id,
        created_at: Time.now,
        log_level: level,
        step: current_step,
        message:
      )
    end

    def script_prompt
      <<-PROMPT.freeze
        In the style of a #{CONFIG.station_era} radio broadcaster, give a news update summarizing the below events.
        Do not read them all individually but group common events and summarize them.
        Do not include sound or music prompts. Mention that the broadcast is for the current time of #{Time.now.strftime('%I:00 %p')}
        The news update should be verbose and loquacious but please do not refer to yourself as either.
        The station name is #{CONFIG.station_frequency} #{CONFIG.station_name} and your radio broadcaster name is #{CONFIG.broadcaster_name}.
        At some point in the broadcast advertise for a fictional product that might have existed in the #{CONFIG.station_era}.
        Give an introduction to the news report and a sign off.
        Here are the events:
      PROMPT
    end

    # rubocop:disable Metrics/AbcSize
    def do_prompt!
      log('Starting Prompt Generation.')
      update(script_started_at: Time.now)

      log('Collecting Events')
      @events = [Event.active.latest_weather.first]
      @events += Event.active.where(source: 'google').latest.limit(100).all
      @events += Event.active.where(source: 'email').latest.limit(30).all
      event_list = @events.compact.map(&:event_text)
      log("Collected #{event_list.count} Events")

      broadcast.update(prompt: "#{script_prompt} #{event_list.join("\n")}")
      log('Finished Prompt Generation.')
    end
    # rubocop:enable Metrics/AbcSize

    def do_script!
      log('Starting Script Generation.')
      update(script_started_at: Time.now, current_step: :script)

      log('Requesting Script')
      messages = [{ role: 'user', content: broadcast.prompt }]
      response = OpenAi.client.chat(parameters: { model: 'gpt-4-1106-preview', messages: })
      script = response.dig('choices', 0, 'message', 'content')
      log('Saving Script')
      broadcast.update(script:)

      update(script_finished_at: Time.now)
      log('Finished Script Generation.')
    end

    def do_vocals!
      log('Starting Vocals Generation.')
      update(vocals_started_at: Time.now, current_step: :vocals)

      ElevenLabs.tts(CONFIG.elevenlabs_voice_id, broadcast.script, 'work/vocals.mp3')

      update(vocals_finished_at: Time.now)
      log('Finished Vocals Generation.')
    end

    def do_mixing!
      log('Starting Mixing.')
      update(vocals_started_at: Time.now, current_step: :mixing)
      update(mixing_started_at: Time.now)

      mixer = AudioMixer.new('work/vocals.mp3')
      mixer.mix

      broadcast.update(length: mixer.final_length, audio_file: mixer.final_file)

      log('Finished Mixing')
      update(mixing_finished_at: Time.now)
    end
end

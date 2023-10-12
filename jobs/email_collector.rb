# frozen_string_literal: true

require 'net/imap'

# Wrapper for getting Emails with pertinent data
class EmailCollector
  def initialize(logger)
    @logger = Logger.new($stdout) if logger.nil?
    @imap = Net::IMAP.new(CONFIG.imap_host, CONFIG.imap_port, true, nil, false)
    @imap.authenticate('LOGIN', CONFIG.imap_login, CONFIG.imap_password)
    @imap.select('INBOX')
  end

  def save_events
    emails.each do |email|
      Event.create(
        created_at: Time.now,
        source: 'email',
        event_text: email_event_text(email),
        raw_source: email.to_json
      )
    end
    purge_mailbox
  end

  private

    def email_event_text(email)
      [
        "An email from #{email.attr['ENVELOPE'].from.first.name}",
        "with a subject of '#{email.attr['ENVELOPE'].subject.gsub(/\p{Emoji_Presentation}/, '').strip}'",
        "was received at #{email.attr['ENVELOPE'].date.to_time.strftime('%D %I:%M:%S %p')}"
      ].join(' ')
    end

    def emails
      return @emails unless @emails.nil?

      search_array = []
      ((search_terms.count * 2) - 1).times { search_array << 'OR' }
      search_terms.each { |term| search_array += ['SUBJECT', term, 'SUBJECT', term.downcase] }
      email_seq_nos = @imap.search(search_array)
      @emails = if email_seq_nos == []
                  []
                else
                  @imap.fetch(email_seq_nos, %w[ENVELOPE UID])
                end
    end

    def search_terms
      return @terms unless @terms.nil?

      @terms = CONFIG.imap_search_terms&.split('|')&.map(&:strip)
    end

    def purge_mailbox
      uids = @imap.uid_search(['ALL'])
      @imap.uid_store(uids, '+FLAGS', [:Deleted])
      @imap.expunge
    end
end

# frozen_string_literal: true

# Wrapper for OpenAI Client
class OpenAi
  def self.client
    return @openai_client unless @openai_client.nil?

    @openai_client = OpenAI::Client.new(
      access_token: CONFIG.openai_access_token,
      organization_id: CONFIG.openai_organization_id
    )
  end
end

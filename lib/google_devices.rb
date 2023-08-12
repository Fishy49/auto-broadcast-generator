# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/smartdevicemanagement_v1'

# Wrapper for authenticating and pulling Google Nest Devices
class GoogleDevices
  SCOPE = 'https://www.googleapis.com/auth/sdm.service'
  PROJECT_PARENT = "enterprises/#{ENV.fetch('GOOGLE_DEVICE_ACCESS_PROJECT_ID', nil)}".freeze

  attr_accessor :client, :token_store, :authorizer, :service

  def initialize
    @client = Google::Auth::ClientId.from_file(ENV.fetch('GOOGLE_DEVICE_ACCESS_OAUTH_CREDENTIAL_FILE', nil))
    @token_store = Google::Auth::Stores::FileTokenStore.new(file: ENV.fetch('GOOGLE_DEVICE_ACCESS_OAUTH_TOKEN_FILE',
                                                                            nil))
    @authorizer = Google::Auth::UserAuthorizer.new(@client, SCOPE, @token_store, '')
    @service = Google::Apis::SmartdevicemanagementV1::SmartDeviceManagementService.new
  end

  def authorized?
    !credentials.nil?
  end

  def save_code(code)
    @authorizer.get_and_store_credentials_from_code(
      user_id: ENV.fetch('GOOGLE_DEVICE_ACCESS_USER_ID', nil),
      code:,
      base_url: ENV.fetch('GOOGLE_DEVICE_ACCESS_REDIRECT_URL', nil)
    )
  end

  def oauth_url
    @authorizer.get_authorization_url(base_url: ENV.fetch('GOOGLE_DEVICE_ACCESS_REDIRECT_URL', nil))
  end

  def nest_oauth_url
    [
      'https://nestservices.google.com/partnerconnections/',
      ENV.fetch('GOOGLE_DEVICE_ACCESS_PROJECT_ID', nil),
      "/auth?redirect_uri=#{ENV.fetch('GOOGLE_DEVICE_ACCESS_REDIRECT_URL', nil)}",
      "&access_type=offline&prompt=consent&client_id=#{@client.id}&response_type=code&scope=#{SCOPE}"
    ].join
  end

  def list(force: false)
    return @list unless @list.nil? || force

    @service.authorization = credentials

    begin
      @list = @service.list_enterprise_devices(PROJECT_PARENT)
    rescue Google::Apis::AuthorizationError
      credentials.refresh!
      @list = @service.list_enterprise_devices(PROJECT_PARENT)
    end
    @list
  end

  def device_names
    return @device_names unless @device_names.nil?

    @device_names = list.devices.map do |d|
      {
        name: d.name,
        title: d.traits['sdm.devices.traits.Info']['customName'],
        type: d.type.split('.').last.downcase.capitalize
      }
    end
    @device_names
  end

  private

    def credentials
      @authorizer.get_credentials(ENV.fetch('GOOGLE_DEVICE_ACCESS_USER_ID', nil))
    end
end

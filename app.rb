# frozen_string_literal: true

require 'dotenv/load'
require 'bundler/setup'
require 'rack-flash'
require 'logger'
require 'pagy'
require 'securerandom'
require 'sqlite3'
require 'sequel'
require 'uri'

Bundler.require

require 'sinatra/reloader' unless ENV['RACK_ENV'] == 'production'

Dir[
  './initializers/*.rb',
  './lib/*.rb',
  './models/*.rb'
].each { |file| require file }

DB.loggers << Logger.new($stdout) unless ENV['RACK_ENV'] == 'production'

CONFIG = Config.new(DB)

helpers do
  include Pagy::Backend
  include Pagy::Frontend

  def partial(template, locals = {})
    erb(template, layout: false, locals:)
  end

  def titleize(str)
    str.to_s.split('_').map(&:capitalize).join(' ')
  end

  def pagy_get_vars(collection, vars)
    {
      count: collection.count,
      page: params['page'],
      items: vars[:items] || 25
    }
  end
end

enable :sessions
use Rack::Flash

get '/' do
  @current_page = :dashboard
  erb :dashboard
end

get '/events/:id' do
  @current_page = :event
  @event = Event[params['id']]
  erb @current_page
end

get '/events' do
  @current_page = :events
  @pagy, @events = pagy(Event.latest)
  erb @current_page
end

get '/broadcast-audio/:id' do
  broadcast = Broadcast[params['id']]
  send_file File.join(broadcast.audio_file)
end

get '/broadcasts/:id' do
  @current_page = :broadcast
  @broadcast = Broadcast[params['id']]
  erb @current_page
end

delete '/broadcast/:id' do
  broadcast = Broadcast[params['id']]
  job = broadcast.broadcast_generation_job
  logs = job.broadcast_generation_job_logs
  logs.delete if logs.count.positive?
  FileUtils.rm_f(broadcast.audio_file)
  job.broadcast.destroy
  job.destroy

  flash[:success] = 'Broadcast Deleted'
  redirect '/broadcasts'
end

get '/broadcasts' do
  @current_page = :broadcasts
  @pagy, @broadcasts = pagy(Broadcast.latest)
  erb @current_page
end

post '/broadcast_configuration' do
  Config::CONFIG_VARS.each do |var|
    CONFIG.public_send("#{var}=", params[var])
  end
  flash[:success] = 'Configuration Saved!'
  redirect '/broadcast_configuration'
end

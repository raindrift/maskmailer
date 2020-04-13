ENV['SINATRA_ENV'] ||= "development"

require 'bundler/setup'
Bundler.require(:default, ENV['SINATRA_ENV'])

require './app/controllers/application_controller'
require './lib/recipient'
require 'rack/ssl-enforcer'
use Rack::SslEnforcer

require_all 'app'

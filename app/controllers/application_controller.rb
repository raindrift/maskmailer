require './config/environment'
require 'json'

class ApplicationController < Sinatra::Base
  include Recaptcha::Adapters::ControllerMethods

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
  end

  configure :test do
    set :raise_errors, true
    set :dump_errors, false
    set :show_exceptions, false
  end

  get "/" do
    erb :welcome
  end

  post "/send" do
    content_type :json

    unless verify_recaptcha
      error 403, 'mailer-captcha-failed'
    end

    validator = Mailgun::Address.new ENV.fetch('MAILGUN_API_KEY')

    to = Recipient.new(params[:to]).email
    unless validator.validate(to)
      error 400, 'mailer-bad-to'
    end

    reply_to = params[:from]
    unless validator.validate(reply_to)
      error 400, 'mailer-bad-from'
    end

    unless params[:message] =~ /^(?!\s*$).+/ # non-blank, non-whitespace string
      error 400, 'mailer-message-blank'
    end

    domain = ENV.fetch('DOMAIN')
    project_name = ENV.fetch('NAME')

    if params[:name] =~ /^(?!\s*$).+/
      from = "#{params[:name]} via #{project_name} <no-reply@#{domain}>"
    else
      from = "#{project_name} <no-reply@#{domain}>"
    end

    client = Mailgun::Client.new ENV.fetch('MAILGUN_API_KEY')
    text = erb(:message, locals: params, layout: nil)
    sent = client.send_message(domain, {
      from: from,
      reply_to: reply_to,
      to: to,
      subject: params[:subject],
      text: text,
    })

    {status: 'success', message: 'mailer-message-sent', text: text}.to_json
  end

  private

  def error code, message
    halt code, {status: 'error', message: message}.to_json
  end

end

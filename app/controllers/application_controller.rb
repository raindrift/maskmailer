require './config/environment'
require 'json'

class ApplicationController < Sinatra::Base
  include Recaptcha::Adapters::ControllerMethods

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'

    # TODO: move this elsewhere
    if ENV["SINATRA_ENV"] == "test"
      set :raise_errors, true
      set :dump_errors, false
      set :show_exceptions, false
    end
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

    from = params[:from]
    unless validator.validate(from)
      error 400, 'mailer-bad-from'
    end

    unless params[:message] =~ /^(?!\s*$).+/ # non-blank, non-whitespace string
      error 400, 'mailer-message-blank'
    end

    client = Mailgun::Client.new ENV.fetch('MAILGUN_API_KEY')
    domain = ENV.fetch('DOMAIN')
    text = erb(:message, locals: params, layout: nil)
    sent = client.send_message(domain, {
      from: "no-reply@#{domain}",
      reply_to: from,
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

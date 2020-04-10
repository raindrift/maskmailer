require './config/environment'

class ApplicationController < Sinatra::Base

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
    client = Mailgun::Client.new ENV.fetch('MAILGUN_API_KEY')
    domain = ENV.fetch('DOMAIN')
    client.send_message(domain, {
      from: "no-reply@#{domain}",
      reply_to: params[:from],
      to: Recipient.new(params[:to]).email,
      subject: params[:subject],
      text: params[:message],
    })

    erb :sent
  end

end

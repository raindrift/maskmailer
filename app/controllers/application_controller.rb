require './config/environment'

class ApplicationController < Sinatra::Base

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'

    # for showing exceptions under test. maybe remove.
    set :raise_errors, true
    set :dump_errors, false
    set :show_exceptions, false
  end

  get "/" do
    erb :welcome
  end

  post "/send" do
    client = Mailgun::Client.new ENV.fetch('MAILGUN_API_KEY')
    client.send_message(ENV.fetch('DOMAIN'), {
      from: params[:from],
      to: Recipient.new(params[:to]).email,
      subject: params[:subject],
      text: params[:message],
    })

    erb :sent
  end

end

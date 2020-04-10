require_relative "spec_helper"

def app
  ApplicationController
end

describe ApplicationController do
  describe "/" do
    it "responds with a welcome message" do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("Welcome to the Sinatra Template!")
    end
  end

  describe "/send" do
    let(:message) { "This is an email." }
    let(:from) { "sender@example.com" }
    let(:to) { "recipient@example.com" }
    let(:to_encrypted) { Recipient.encode_email(to)}
    let(:subject) { "The message subject" }
    let(:params) { {message: message, from: from, to: to_encrypted, subject: subject} }

    let(:client) { Mailgun::Client.new 'test-api-key' }
    let(:domain) { 'example.com' }

    before do
      client.enable_test_mode!
      Mailgun::Client.deliveries.clear
      allow(Mailgun::Client).to receive(:new).and_return(client)
      allow(ENV).to receive(:fetch).with('FROM').and_return(from)
      allow(ENV).to receive(:fetch).with('DOMAIN').and_return(domain)
      allow(ENV).to receive(:fetch).with('MAILGUN_API_KEY').and_return('test-api-key')
      allow(ENV).to receive(:fetch).with('RECIPIENT_KEY').and_return('lhVIO5YBMqXZYECJEUWHQlWqzlk90zKd')
    end

    it 'receives message via POST' do
      post '/send', **params

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("Your message has been sent")
    end

    it 'sends the email to the recipient using the encrypted address' do
      post '/send', **params

      sent = Mailgun::Client.deliveries.first
      expect(sent).to be
      expect(sent[:from]).to eq 'no-reply@example.com'
      expect(sent[:to]).to eq to
      expect(sent[:subject]).to eq subject
    end

    it 'sets the reply-to properly' do
      post '/send', **params
      sent = Mailgun::Client.deliveries.first
      expect(sent[:reply_to]).to eq from
    end

    it 'has a captcha'
    it 'shows the user the message they sent'

    context 'with newlines in the message' do
      it 'handles the newlines gracefully'
    end

    context 'with unicode characters in the message' do
      it 'properly encodes the unicode'
    end

    context 'with unicode in the addresses' do
      it 'properly decrypts the to address'
      it 'uses the correct from address'
    end

    context 'when provided with invalid data' do
      it 'fails for bad addresses'
      it 'fails for a blank message'
    end
  end
end

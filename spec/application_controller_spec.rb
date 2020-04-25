require_relative "spec_helper"
require 'json'

def app
  ApplicationController
end

describe ApplicationController do
  describe "/" do
    it "responds with a placeholder" do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("droids")
    end
  end

  describe "/send" do
    let(:text) { "This is an email." }
    let(:from) { "reply@example.com" }
    let(:to) { "recipient@example.com" }
    let(:to_encrypted) { Recipient.encode_email(to) }
    let(:subject) { "The message subject" }
    let(:name) { "" }
    let(:introduction) { "This message was sent via foo.com. You can reply directly to the sender." }
    let(:params) do
      {
        text: text,
        from: from,
        to: to_encrypted,
        subject: subject,
        introduction: introduction,
        name: name,
      }
    end

    let(:client) { Mailgun::Client.new 'test-api-key' }
    let(:valid_email) { {result: 'deliverable'} }
    let(:invalid_email) { {result: 'undeliverable'} }
    let(:validator) { double(:mailgun_address, validate: valid_email) }

    let(:domain) { 'example.com' }

    let(:captcha_verified) { true }

    before do
      client.enable_test_mode!
      Mailgun::Client.deliveries.clear
      allow(Mailgun::Client).to receive(:new).and_return(client)
      allow(Mailgun::Address).to receive(:new).and_return(validator)

      allow_any_instance_of(Recaptcha::Adapters::ControllerMethods).to receive(:verify_recaptcha).and_return(captcha_verified)

      allow(ENV).to receive(:fetch).with('FROM').and_return(from)
      allow(ENV).to receive(:fetch).with('DOMAIN').and_return(domain)
      allow(ENV).to receive(:fetch).with('MAILGUN_API_KEY').and_return('test-api-key')
      allow(ENV).to receive(:fetch).with('MAILGUN_VALIDATION_KEY').and_return('test-validation-key')
      allow(ENV).to receive(:fetch).with('RECIPIENT_KEY').and_return('lhVIO5YBMqXZYECJEUWHQlWqzlk90zKd')
      allow(ENV).to receive(:fetch).with('NAME').and_return('Find The Masks')
    end

    it 'receives message via POST, responds via json, includes message text' do
      post '/send', **params

      expect(last_response.status).to eq(200)
      response = JSON.parse(last_response.body)
      expect(response['status']).to eq 'success'
      expect(response['message']).to eq 'mailer-message-sent'
      expect(response['text']).to match /sent via foo\.com/
      expect(response['text']).to match /findthemasks.com/
      expect(response['text']).to match /This is an email./
    end

    it 'sends the email to the recipient using the encrypted address' do
      post '/send', **params

      sent = Mailgun::Client.deliveries.first.message
      expect(sent).to be
      expect(sent[:from]).to eq ['Find The Masks <reply@example.com>']
      expect(sent[:to]).to eq [to]
      expect(sent[:subject]).to eq [subject]

      text = sent[:text].first
      # check that the message body was included.
      expect(text).to match /sent via foo\.com/
      expect(text).to match /findthemasks.com/
      expect(text).to match /This is an email./
    end

    it 'sets the reply-to properly' do
      post '/send', **params
      sent = Mailgun::Client.deliveries.first.message
      expect(sent['h:reply-to']).to eq from
    end

    context 'with a sender name' do
      let(:name) { "Mr. Foo" }

      it 'includes the sender name in From:' do
        post '/send', **params
        sent = Mailgun::Client.deliveries.first.message
        expect(sent[:from]).to eq ['Mr. Foo via Find The Masks <reply@example.com>']
      end
    end

    context 'when captcha verification fails' do
      let(:captcha_verified) { false }

      it 'returns an error' do
        post '/send', **params

        expect(last_response.status).to eq(403)
        response = JSON.parse(last_response.body)
        expect(response['status']).to eq 'error'
        expect(response['message']).to eq 'mailer-captcha-failed'
      end
    end

    context 'with newlines in the message' do
      it 'handles the newlines gracefully'
    end

    context 'with unicode characters in the message and address' do
      let(:text) { "これはなんですか？" }
      let(:from) { 'まる君 <maru@example.com>' }

      it 'properly encodes the unicode in the response and the message' do
        post '/send', **params
        response = JSON.parse(last_response.body)
        expect(response['text']).to match text

        sent = Mailgun::Client.deliveries.first.message
        expect(sent['h:reply-to']).to eq from
        expect(sent[:text].first).to match text
      end
    end

    context 'when provided with invalid data' do
      context 'with a bad from address' do
        before do
          expect(validator).to receive(:validate).with(from).and_return invalid_email
        end

        it 'fails' do
          post '/send', **params
          response = JSON.parse(last_response.body)
          expect(response['status']).to eq 'error'
          expect(response['message']).to eq 'mailer-bad-from'
        end
      end

      context 'with a bad to address' do
        before do
          expect(validator).to receive(:validate).with(to).and_return invalid_email
        end

        it 'fails' do
          post '/send', **params
          response = JSON.parse(last_response.body)
          expect(response['status']).to eq 'error'
          expect(response['message']).to eq 'mailer-bad-to'
        end
      end

      context 'with a blank message' do
        let(:text) { "" }
        it 'fails' do
          post '/send', **params
          response = JSON.parse(last_response.body)
          expect(response['status']).to eq 'error'
          expect(response['message']).to eq 'mailer-message-blank'
        end
      end

      context 'with a blank subject' do
        let(:subject) { "" }
        it 'fails' do
          post '/send', **params
          response = JSON.parse(last_response.body)
          expect(response['status']).to eq 'error'
          expect(response['message']).to eq 'mailer-subject-blank'
        end
      end

      context 'with an all-whitespace message' do
        let(:text) { "   \n   " }
        it 'fails' do
          post '/send', **params
          response = JSON.parse(last_response.body)
          expect(response['status']).to eq 'error'
          expect(response['message']).to eq 'mailer-message-blank'
        end
      end
    end
  end


  describe "/decrypt" do
    it "fails without auth" do
      get '/decrypt'
      expect(last_response.status).to eq(401)
    end
  end

  describe "/compose" do
    it "fails without auth" do
      get '/compose'
      expect(last_response.status).to eq(401)
    end
  end

  describe "/process_decrypt" do
    it "fails without auth" do
      get '/process_decrypt'
      expect(last_response.status).to eq(401)
    end
  end

  context 'when authenticated' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:protected!)
    end

    describe "/decrypt" do
      it "presents a simple crypto test form" do
        get '/decrypt'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("Encrypted email address")
      end
    end

    describe "/compose" do
      it "presents a compose form" do
        get '/compose'
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("Encrypted email address")
        expect(last_response.body).to include("Compose")
      end
    end

    describe "/process_decrypt" do
      let(:captcha_verified) { true }
      let(:recipient) { Recipient.encode_email('foo@example.com') }

      before do
        allow_any_instance_of(Recaptcha::Adapters::ControllerMethods).to receive(:verify_recaptcha).and_return(captcha_verified)
      end

      it "decripts the presented text" do
        get '/process_decrypt', recipient: recipient
        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("foo@example.com")
      end

      context 'when captcha verification fails' do
        let(:captcha_verified) { false }

        it 'returns an error' do
          get '/process_decrypt', recipient: recipient

          expect(last_response.status).to eq(403)
          expect(last_response.body).to include("Captcha failed")
        end
      end
    end
  end
end

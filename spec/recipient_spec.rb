require_relative "spec_helper"

describe 'Recipient' do

  let(:email) { 'foo@bar.com' }
  let(:ciphertext) { Recipient.encode_email(email) }

  before do
    allow(ENV).to receive(:fetch).with('RECIPIENT_KEY').and_return('lhVIO5YBMqXZYECJEUWHQlWqzlk90zKd')
  end

  it 'encrypts and then decrypts the email address' do
    recipient = Recipient.new ciphertext
    expect(recipient.email).to eq 'foo@bar.com'
  end

  it 'works correctly with a utf-8 string'

end

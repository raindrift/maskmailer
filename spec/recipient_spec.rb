require_relative "spec_helper"

describe 'Recipient' do

  let(:email) { 'Mr. Foo <foo@bar.com>' }
  let(:ciphertext) { Recipient.encode_email(email) }

  before do
    allow(ENV).to receive(:fetch).with('RECIPIENT_KEY').and_return('lhVIO5YBMqXZYECJEUWHQlWqzlk90zKd')
  end

  it 'encrypts and then decrypts the email address' do
    recipient = Recipient.new ciphertext
    expect(recipient.email).to eq email
  end

  context 'with a utf-8 name part in the address' do
    let(:email) { 'まる君 <maru@example.com>' }
    it 'still works' do
      recipient = Recipient.new ciphertext
      expect(recipient.email).to eq email
    end
  end

end

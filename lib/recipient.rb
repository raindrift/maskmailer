require 'openssl'
require 'base64'
require 'json'

class Recipient
  def initialize(ciphertext)
    recipient = JSON.parse(Recipient.decrypt(ciphertext))
    @email = recipient['email']
  end

  attr_reader :email

  # for the moment this is used mostly in testing
  def self.encode_email(recipient)
    json = JSON.generate({email: recipient})
    self.encrypt(json)
  end

  CIPHER = 'aes-256-cbc'

  def self.encrypt(cleartext)
      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.encrypt
      cipher.key = ENV.fetch('RECIPIENT_KEY')
      iv = cipher.random_iv
      cipher.iv = iv
      result = cipher.update(cleartext)
      result << cipher.final
      Base64.encode64(iv + result)  # iv is the first 16 bytes
  end

  def self.decrypt(ciphertext)
      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.decrypt
      cipher.key = ENV.fetch('RECIPIENT_KEY')
      decoded = Base64.decode64(ciphertext)
      cipher.iv = decoded[0..15]  # iv is the first 16 bytes
      result = cipher.update(decoded[16..-1])
      result << cipher.final
  end
end

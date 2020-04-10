# Installing

Set up rbenv:

    brew install rbenv

...then follow the instructions. Once you have the correct Ruby version
installed, install the gems:

    gem install bundler
    bundle install

# Setup

You'll need a `.env` file with the following:

    MAILGUN_API_KEY=(an api key)
    FROM=(the address to send from)
    DOMAIN=(the sending domain)
    RECIPIENT_KEY=(a 32-byte key for decrypting the recipient)

# Running the server in dev

Start the server with shotgun:

    shotgun

# Encrypted address format

The `To:` address should be stored in a JSON blob as follows:

    { "email": "foo@example.com" }

This is encrypted using `aes-256-cbc` (we're using the Openssl implementation)
with a shared key and a random 16-byte initialization vector. The iv is then
prepended to the message, and it is base64 encoded.

There is a sample `encrypt` method in `lib/recipient.rb`

The following JavaScript code should also work

    var recipient = {email: "foo@example.com"};

    var crypto = require('crypto'),
        cipherName = 'aes-256-cbc',
        key = 'SHARED_KEY_32_CHR_12345678901234'; // 32 Characters

    function encrypt(recipient){
      var json = JSON.stringify(recipient);
      var iv = crypto.randomBytes(16);
      var cipher = crypto.createCipheriv(cipherName,key,iv)
      var crypted = cipher.update(json,'utf-8')
      crypted += cipher.final();
      var ciphertext = Buffer.concat([iv, crypted], iv.length + crypted.length);
      return cipherText.toString('base64');
    }

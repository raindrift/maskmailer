# Intro

This is a little app for emailing the results of forms to people, without
revealing the recipient's email address, and preventing abuse as a generic
mail relay. Built to drive the contact form at findthemasks.com.

# Primary endpoint

This app hosts a single primary endpoint, `/send`, which accepts parameters
via HTTP POST and responds with JSON.

## Parameters

You'll need to supply the following params:

- `to`: The encrypted recipient (see below)
- `from`: The cleartext From: address
- `name`: Sender's name
- `subject`: Message subject line
- `text`: Message text
- `introduction`: Preamble, inserted before the message text.

The `introduction` is provided by the client with each request so that it can be translated.

## Encrypted address format

The `To:` address should be stored in a JSON blob as follows:

    { "email": "foo@example.com" }

This is encrypted using `aes-256-cbc` (we're using the Openssl implementation)
with a shared key and a random 16-byte initialization vector. The iv is then
prepended to the ciphertext, is base64 encoded, and then is urlencoded so it
can be represented on a single line.

There is a sample Ruby `encrypt` method in `lib/recipient.rb`

The following JavaScript code should also work

    var recipient = {email: "foo@example.com"};

    var crypto = require('crypto'),
        key = 'SHARED_KEY_32_CHR_12345678901234'; // 32 Characters

    function encrypt(recipient){
      var json = JSON.stringify(recipient);
      var iv = crypto.randomBytes(16);
      var cipher = crypto.createCipheriv('aes-256-cbc',key,iv)
      var ciphertext = cipher.update(json,'utf-8')
      ciphertext += cipher.final();
      var result = Buffer.concat([iv, ciphertext], iv.length + ciphertext.length);
      return encodeURIComponent(result.toString('base64'));
    }

## Real-world testing

To check that your sender data is properly encrypted and encoded, visit
`/decrypt` where you can find a simple webform to test it.

To send a test email with your encrypted address, visit `/compose`

To encrypt an address, from the project root run:

    scripts/encrypt-email.rb foo@example.com

# Development setup

## Installing

Set up rbenv:

    brew install rbenv

...then follow the instructions. Once you have the correct Ruby version
installed, install the gems:

    gem install bundler
    bundle install

## Setup

You'll need a `.env` file with the following:

    MAILGUN_API_KEY=(an api key)
    MAILGUN_VALIDATION_KEY=(a public key for the validation api)
    FROM=(the address to send from)
    DOMAIN=(the sending domain)
    RECIPIENT_KEY=(a 32-byte key for decrypting the recipient)
    RECAPTCHA_SITE_KEY=(the site key for recaptcha)
    RECAPTCHA_SECRET_KEY=(the secret key for recaptcha)

## Running the server in dev

Start the server with shotgun:

    shotgun

## Testing

You can run the test suite by running `rspec` with no args.

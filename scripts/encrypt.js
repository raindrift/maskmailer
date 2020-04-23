#!/usr/bin/env node

var recipient = {email: "foo@example.com"};

var crypto = require('crypto'),
    key = 'SHARED_KEY_32_CHR_12345678901234'; // 32 Characters

function encrypt(recipient){
  var json = JSON.stringify(recipient);
  var iv = crypto.randomBytes(16);
  var cipher = crypto.createCipheriv('aes-256-cbc',key,iv)
  var ciphertext = cipher.update(json,'utf-8','latin1')
  ciphertext += cipher.final('latin1');
  var cipherBuffer = Buffer.from(ciphertext, 'latin1');
  var result = Buffer.concat([iv, cipherBuffer], iv.length + cipherBuffer.length);
  return encodeURIComponent(result.toString('base64'));
}

console.log('result', encrypt(recipient));

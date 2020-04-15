#!/usr/bin/env ruby
require './config/environment'
Dotenv.load
print "#{Recipient.encode_email(ARGV[0])}\n"

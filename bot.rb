require 'rubygems'
require 'isaac'
require 'rest_client'
require 'json'

config do |c|
  c.nick    = 'nancie'
  c.server  = 'irc.freenode.net'
end

on :connect do
  join "#sinatra"
end

on :channel, /^nancie.*tweet this: (.*)/ do
  RestClient.post 'http://sinatrarb:somepassword@twitter.com/statuses/update.json', :status => match[1]
end

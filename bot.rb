require 'rubygems'
require 'isaac'
require 'rest_client'
require 'json'

ALLOWED = %w(rtomayko blakemizerany cypher23 harryjr sr ...)

config do |c|
  c.nick    = 'nancie'
  c.server  = 'irc.freenode.net'
end

on :connect do
  join "#sinatra"
end

on :channel, /^nancie.*tweet this: (.*)/ do
  if ALLOWED.include?(nick)
    RestClient.post 'http://sinatrarb:somepassword@twitter.com/statuses/update.json', :status => match[1]
  else
    msg nick, "We're fucking nijas! move, bitch!"
  end
end

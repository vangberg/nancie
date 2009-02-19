# Meh, I went overboard. Usage:
#
# To tweet, write in channel:
#   nancie, tweet this: some nice thing about sinatra and stuff
# To give permissions, private message:
#   /msg nancie allow awesome_user
#
# Additional extensions are welcome.

require 'rubygems'
require 'isaac'
require 'rest_client'
require 'yaml'
require 'json'

module Nancie
  extend self

  attr_reader :config

  def load_config
    @config = YAML.load_file('config.yml')
  end

  def write_config
    File.open('config.yml', 'w') { |f| YAML.dump(@config, f) }
  end

  def allowed?(nick)
    config['allowed'].include?(nick)
  end

  def allow!(nick)
    @config['allowed'] << nick
    write_config
  end
end

Nancie.load_config

config do |c|
  c.nick    = 'nancie'
  c.server  = 'irc.freenode.net'
end

helpers do
  def twitter(url, params={})
    JSON.parse(RestClient.post "http://sinatra:#{Nancie.config['twitter_password']}@twitter.com/" + url + ".json", params)
  end
end

on :connect do
  join '#sinatra'
  msg 'nickserv', "identify #{Nancie.config['nickserv_password']}"
end

on :channel, /^nancie.*tweet this: (.*)/ do
  if Nancie.allowed?(nick)
    reply = twitter "statuses/update", :status => match[1]
    msg channel, "#{nick}, http://twitter.com/sinatra/status/#{reply['id']}"
  else
    msg nick, "We're fucking ninjas! Move, bitch!"
  end
end

on :channel, /^nancie.* follow (\S+)/ do
  begin
    if Nancie.allowed?(nick)
      follow = match[1]
      reply = twitter "friendships/create/#{follow}"
      msg channel, "#{nick}, we're now following #{reply['screen_name']}."
    end
  rescue
    msg channel, "#{nick}, something went wrong as I tried to follow #{follow}."
  end
end

on :private, /^allow (\S+)/ do
  to_allow = match[1]
  if Nancie.allowed?(nick)
    Nancie.allow!(to_allow)
    msg nick, "#{to_allow} has throwing stars!"
  else
    msg nick, "Lulz, where are your throwing stars?"
  end
end

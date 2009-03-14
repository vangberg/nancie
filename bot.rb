# Meh, I went overboard. Usage:
#
# To tweet, write in channel:
#   nancie, tweet this: some nice thing about sinatra and stuff
# To give permissions, private message:
#   /msg nancie allow awesome_user
#
# Additional extensions are welcome.

require 'rubygems'
require 'isaac' # requires 0.2 / shaft
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

  def twitter_credentials
    "#{config['twitter']['login']}:#{config['twitter']['password']}"
  end
end

Nancie.load_config

configure do |c|
  c.nick    = Nancie.config['irc']['nick']
  c.server  = Nancie.config['irc']['server']
  c.port    = Nancie.config['irc']['port'] || 6667
end

helpers do
  def twitter(url, params={})
    JSON.parse(RestClient.post "http://#{Nancie.twitter_credentials}@twitter.com/" + url + ".json", params)
  end

  def ensure_permissions
    halt unless Nancie.allowed?(nick)
  end
end

on :connect do
  join "##{Nancie.config['irc']['channel']}"
  msg 'nickserv', "identify #{Nancie.config['irc']['nickserv']}"
end

on :channel, /^#{Nancie.config['irc']['nick']}.*tweet this: (.*)/ do
  ensure_permissions
  reply = twitter "statuses/update", :status => match[0]
  msg channel, "#{nick}, http://twitter.com/#{Nancie.config['twitter']['login']}/status/#{reply['id']}"
end

on :channel, /^#{Nancie.config['irc']['nick']}.* follow (\S+)/ do
  ensure_permissions
  begin
    follow = match[0]
    reply = twitter "friendships/create/#{follow}"
    msg channel, "#{nick}, we're now following #{reply['screen_name']}."
  rescue
    msg channel, "#{nick}, something went wrong as I tried to follow #{follow}."
  end
end

on :channel, /^#{Nancie.config['irc']['nick']}.* show (\S+) (.*)/ do
  ensure_permissions
  tags = match[1].tr(" ", "/")
  msg channel, "#{match[0]}, take a look at http://sinatra-cheat.heroku.com/#{tags}"
end

on :channel, /^#{Nancie.config['irc']['nick']}.* tag (\d+) as (.*)/ do
  ensure_permissions
  begin
    RestClient.post "http://sinatra-cheat.heroku.com/",
      :gist => match[0],
      :tags => match[1]
    tags = match[1].tr(" ", "/")
    msg channel, "#{nick}, http://sinatra-cheat.heroku.com/#{tags}"
  rescue
    msg channel, "#{nick}, something went wrong.."
  end
end

on :private, /^allow (\S+)/ do
  ensure_permissions

  allow = match[0]
  Nancie.allow!(allow)
  msg nick, "#{allow} has throwing stars!"
end

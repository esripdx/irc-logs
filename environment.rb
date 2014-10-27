ENV['TZ'] = 'UTC'
Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'cgi'

Bundler.require
Dir.glob(['lib'].map! {|d| File.join File.expand_path(File.dirname(__FILE__)), d, '*.rb'}).each {|f| require f}

SiteConfig = YAML.load_file('config.yml') if File.exists?('config.yml')

class Controller < Sinatra::Base
  configure do
    set :root, File.dirname(__FILE__)

    use OmniAuth::Builder do
      provider :github, SiteConfig['github']['client_id'], SiteConfig['github']['client_secret'], :client_options => { :ssl => { :version => "TLSv1" } }
    end
    OmniAuth.config.full_host = SiteConfig['base']

    DB = Sequel.connect SiteConfig['mysql']

    set :public_folder, File.dirname(__FILE__) + '/public'
    set :sessions, true
    set :session_secret, "aisudhgaih94hg9wurhguhsdf"
  end

  def _date(timestamp, timezone)
    offset = format('%+05d', Rational(timezone.utc_offset,86400)*24*100)
    DateTime.strptime(timestamp.to_s, '%s').new_offset(offset)
  end

  def _date_format(timestamp, timezone, format)
    _date(timestamp, timezone).strftime(format)
  end
end

require_relative './controller.rb'
Dir.glob(['controllers'].map! {|d| File.join d, '*.rb'}).each do |f| 
  require_relative f
end


require 'rubygems'
require 'bundler'

Bundler.require

use Rack::Cors do
  # allow do
  #   origins 'localhost:3000', '127.0.0.1:3000',
  #           /http:\/\/192\.168\.0\.\d{1,3}(:\d+)?/
  #           # regular expressions can be used here

  #   resource '/file/list_all/', :headers => 'x-domain-token'
  #   resource '/file/at/*',
  #       :methods => [:get, :post, :put, :delete],
  #       :headers => 'x-domain-token',
  #       :expose => ['Some-Custom-Response-Header']
  #       # headers to expose
  # end

  allow do
    origins '*'
    resource '/*', :headers => :any, :methods => [:get, :post, :put, :delete, :patch]
  end
end

require './drowsy_dromedary'
run DrowsyDromedary
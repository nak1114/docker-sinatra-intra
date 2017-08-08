# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'sinatra-websocket'

require_relative '../helpers/html_helpers'
require_relative '../helpers/home_helpers'

module MyAppRoute
end
class MyAppRoute::Home < Sinatra::Base
  configure do
    helpers MyAppHelper::HTML
    helpers MyAppHelper::Home

    register Sinatra::CrossOrigin
    
    enable :cross_origin
    set :allow_origin, :any
    set :allow_methods, [:get, :post, :options]

    set :sockets, []
  end
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    slim :home
  end

  @@messages=[]
  @@mutex=Mutex.new

  get '/websocket' do
    if request.websocket? then
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
          @@messages[2]=get_dirinfo()
          ws.send(@@messages.to_json)
        end
        ws.onmessage do |msg|
          # p settings.sockets
          json = JSON.parse msg
          case json['action']
          when 'tr'
            t = Thread.new do
              tr2zip(@@mutex,@@messages,json) unless @@messages[0]
            end
          when 'pdf'
            t = Thread.new do
              zip2zip(@@mutex,@@messages,json) unless @@messages[1]
            end
          end
        end
        ws.onclose do
          settings.sockets.delete(ws)
        end
      end
    end
  end

end
__END__

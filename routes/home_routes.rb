# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'sinatra-websocket'

module MyAppRoute
end
class MyAppRoute::Home < Sinatra::Base
  configure do

    register Sinatra::CrossOrigin
    
    enable :cross_origin
    set :allow_origin, :any
    set :allow_methods, [:get, :post, :options]

    set :sockets, []
  end
  configure :development do
    register Sinatra::Reloader
  end

  def link_to(obj, txt=nil)
    url=obj
    url="#{request.path_info}/#{obj.id}" if obj.class!=String
    txt||=url
    "<a href='#{url}'>#{txt}</a>"
  end


  get '/' do
    slim :home
  end

  @@messages=[]
  @@mutex=Mutex.new

  def wtest
    t = Thread.new do
      curapp=0
      data=[{
        action: 'tr',
          total: 5,
          complete: 0
      }]
      @@mutex.synchronize {
        @@messages[curapp]=data[curapp]
      }
      data[curapp][:total].times do |v|
        p v
        data[curapp][:complete]=v
        senddata=data.to_json
        p senddata
        @@mutex.synchronize {
          settings.sockets.each do |s|
            s.send(senddata)
          end
        }
        sleep 5
      end
      data[curapp][:complete]=data[curapp][:total]
      senddata=data.to_json
      @@mutex.synchronize {
        settings.sockets.each do |s|
          s.send(senddata)
        end
        @@messages[curapp]=nil
      }
    end
  end

  def wtest2
    t = Thread.new do
      curapp=1
      data=[{},{
        action: 'pdf',
          total: 30,
          complete: 0
      }]
      @@mutex.synchronize {
        @@messages[curapp]=data[curapp]
      }
      data[curapp][:total].times do |v|
        p v
        data[curapp][:complete]=v
        senddata=data.to_json
        p senddata
        @@mutex.synchronize {
          settings.sockets.each do |s|
            s.send(senddata)
          end
        }
        sleep 1
      end
      data[curapp][:complete]=data[curapp][:total]
      senddata=data.to_json
      @@mutex.synchronize {
        settings.sockets.each do |s|
          s.send(senddata)
        end
        @@messages[curapp]=nil
      }
    end
  end

  get '/websocket' do
    if request.websocket? then
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
          ws.send(@@messages.to_json)
        end
        ws.onmessage do |msg|
          p settings.sockets
          json = JSON.parse msg
          if json['action']=='tr'
            wtest unless @@messages[0]
          elsif json['action']=='pdf'
            wtest2 unless @@messages[1]
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

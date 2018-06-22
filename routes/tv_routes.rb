# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'sinatra-websocket'
require 'will_paginate/view_helpers/sinatra'
require 'will_paginate/active_record'

require 'cgi'
require 'levenshtein'

require 'pp'

require_relative '../helpers/html_helpers'
require_relative '../helpers/tv_list_helpers'

module MyAppRoute
end
class MyAppRoute::TVList < Sinatra::Base

  configure do
    helpers MyAppHelper::HTML
    helpers MyAppHelper::TvList
    #helpers WillPaginate::Sinatra, WillPaginate::Sinatra::Helpers

    register Sinatra::CrossOrigin

    enable :cross_origin
    set :allow_origin, :any
    set :allow_methods, [:get, :post, :options]

    set :sockets, []

  end
  configure :development do
    register Sinatra::Reloader
    also_reload '/myapp/**/*.rb'
  end


  post '/tv' do
    @pa= params
    @list=tv_flist
    flist=[]
    if params[:list]
      flist=params[:list].map{|v| CGI.unescape(v)}
    end

    if params[:action]=="sort"
      t = Thread.new do
        sort_files(flist,params[:skip_final_check].nil?)
      end
    elsif params[:action]=="add"
      add_lists(flist)
    end


    slim :tv

  end

  get '/tv/list' do
    @dirs=TvList.includes(:status).all.order(updated_at: :desc)
    slim :tv_list
  end

  get '/tv' do
    
    @pa= ""
    @list=tv_flist

    slim :tv
  end

  get '/tv/websocket.ws' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
          #ws.send(@@messages.to_json)
        end
        ws.onmessage do |msg|
          # p settings.sockets
          json = JSON.parse msg
          case json['action']
          when 'add'
            t = Thread.new do
              #tr2zip(@@mutex,@@messages,json) unless @@messages[0]
            end
          when 'sort'
            t = Thread.new do
              #zip2zip(@@mutex,@@messages,json) unless @@messages[1]
            end
          end
        end
        ws.onclose do
          settings.sockets.delete(ws)
        end
      end
    end
  end

  after do
    ActiveRecord::Base.connection.close
  end
end

__END__

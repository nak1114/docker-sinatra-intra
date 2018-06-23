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

  post '/tv/move' do
    t = Thread.new do
      if params[:dir]
        flist=params[:files].map{|v| CGI.unescape(v)}
        dstDir=SortedDir+CGI.unescape(params[:dir])+"/"
        FileUtils.mkdir_p(dstDir) unless Dir.exist?(dstDir)
        flist.each do |fname|
          FileUtils.mv(UnsortDir+fname+'.ts',dstDir)
        end
        sleep 1
        info "ˆÚ“®Š®—¹"
      else
        sleep 1
        info "ˆÚ“®æ‚È‚µ"
      end
    end
    redirect to("/tv")
  end
  post '/tv' do
    @pa= ""
    @list=tv_flist
    @flist=(params[:list]||[]).map{|v| CGI.unescape(v)}

    if params[:action]=="sort"
      t = Thread.new do
        sort_files(@flist,params[:skip_final_check].nil?)
      end
    elsif params[:action]=="move" && params[:list]
      @dirs=AppendDir + TvList.where(status_id: 4).order(updated_at: :desc).map{|v|v.name}
      return slim :tv_move
    elsif params[:action]=="add"
      add_lists(@flist)
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

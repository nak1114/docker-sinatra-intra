# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
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
    helpers WillPaginate::Sinatra, WillPaginate::Sinatra::Helpers

    register Sinatra::CrossOrigin

    enable :cross_origin
    set :allow_origin, :any
    set :allow_methods, [:get, :post, :options]
  end
  configure :development do
    register Sinatra::Reloader
    also_reload '/myapp/**/*.rb'
  end


  post '/tv' do
    @pa= params.to_s
    flist=[]
    if params[:list]
      flist=params[:list].map{|v| CGI.unescape(v)}
    end
#    @title_list=TvList.create(:status).order(:updated_at).reverse_order

    if params[:action]=="sort"
      t = Thread.new do
        tv_sort(flist)
      end
    elsif params[:action]=="add"
      flist.each do |v|
        dir_name=v
            .sub(/[@ \r\n\t]*(\[.*\]_‘æ\d+˜b.*)?$/,'')
            .sub(/^[@ \r\n\t]*/,'').strip 
        columns={}
        columns[:name]=dir_name
        TvList.create(columns.merge({status_id: 4}))
      end
    end

    @list=tv_flist

    slim :tv

  end

  get '/tv/list' do
    @dirs=TvList.includes(:status).all.order(updated_at: :desc)
    slim :tv_list
  end

  get '/tv' do
    
    @pa= params.to_s
    @list=tv_flist

    slim :tv
  end

  after do
    ActiveRecord::Base.connection.close
  end
end

__END__

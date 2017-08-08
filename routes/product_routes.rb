# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'will_paginate/view_helpers/sinatra'
require 'will_paginate/active_record'

require_relative '../helpers/html_helpers'
require_relative '../helpers/product_helpers'
module MyAppRoute
end
class MyAppRoute::Product < Sinatra::Base
  configure do
    helpers MyAppHelper::HTML
    helpers MyAppHelper::Product
    helpers WillPaginate::Sinatra, WillPaginate::Sinatra::Helpers

    register Sinatra::CrossOrigin

    enable :cross_origin
    set :allow_origin, :any
    set :allow_methods, [:get, :post, :options]
  end
  configure :development do
    register Sinatra::Reloader
  end


  get '/pdf' do
    @statuses=Status.all
    @pages=Product.includes(:status).search(params[:keyword]).sfilter(params[:status]).order(:updated_at).reverse_order.paginate(:page => params[:page], :per_page => 50)
    slim :pdf
  end

  post '/pdf' do
    body = request.body.read
    params= JSON.parse body
    if Product.exists?(url: params['url'])
      return {
        warn: '重複',
        status: 'URL重複',
        title: params['name'],
        url: params['url'],
      }.to_json
    end
    name=params['name'].to_fname

    dup=Product.where(name: name).count
    #id=params['url'].sub(%r!\A.*/item/(.*)\z!,"\\1")
    pd=Product.new
    pd.url =params['url']
    pd.name=name
    pd.status_id=1
    
    json = if dup>0
      params['rename']=name+(dup+1).to_s
      pd.rename=params['rename']
      name=params['rename']
      {
        warn: '重複',
        status: '重複&リネーム',
        title: name,
        url: params['url'],
      }
    else
      {
        status: '下戴',
        title: name,
        url: params['url'],
      }
    end
    ret=dl(params['url'],name)
    if ret["success"]
      pd.save
      return json.to_json
    end
    return {
      warn: '無効',
      status: 'StationError',
      title: name,
      url: params['url'],
    }.to_json
  end

  post '/pdf/:id/reload' do |id|
    @page=Product.find(id.to_i)

    name=@page.rename
    name=@page.name if name==nil || name==''
    name=name.to_fname
    ret=dl(@page.url,name)
    if ret["success"]
      @page.update({status_id: 1})
      return {
        message: '完了！'+name,
        rename: name
      }.to_json
    else
      @page.update({status_id: 2})
      return {
        error:  'エラー',
        message: 'Stationエラー',
      }.to_json
    end
  end


  get '/pdf/:id' do |id|
    @statuses=Status.all
    @page=Product.find(id.to_i)
    slim :pdf_id
  end

  post '/pdf/:id' do |id|
    @page=Product.find(id.to_i)
    @statuses=Status.all
    colums={}
    colums[:name]  =params["name"].to_fname   if params["name"]   && params["name"].size >2
    colums[:rename]=params["rename"].to_fname if params["rename"] && params["rename"].size >2
    colums[:status_id]=params["status"].to_i
    @page.update(colums)

    if params["dl"]=='on' && (colums[:status_id]==4 ||colums[:status_id]==5 )
      name=@page.rename
      name=@page.name if name==nil || name==''
      name=name.to_fname
      ret=dl(@page.url,name)
      if ret["success"]
        @page.update({status_id: 1})
      else
        @page.update({status_id: 2})
      end
    end
    slim :pdf_id
  end

  delete '/pdf/:id' do |id|
    body = request.body.read
    json = JSON.parse body
    pp params
    pp json
    {
      message: 'complete!'
    }.to_json
  end

  after do
    ActiveRecord::Base.connection.close
  end
end

__END__

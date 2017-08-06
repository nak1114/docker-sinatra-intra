# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'will_paginate/view_helpers/sinatra'
require 'will_paginate/active_record'

require_relative '../helpers/html_helpers'
require_relative '../helpers/tr_list_helpers'
module MyAppRoute
end
class MyAppRoute::TrList < Sinatra::Base
  configure do
    helpers MyAppHelper::HTML
    helpers MyAppHelper::TrList
    helpers WillPaginate::Sinatra, WillPaginate::Sinatra::Helpers

    register Sinatra::CrossOrigin
    
    enable :cross_origin
    set :allow_origin, :any
    set :allow_methods, [:get, :post, :options]
  end
  configure :development do
    register Sinatra::Reloader
  end

  get '/tr' do
    @statuses=Status.all
    @pages=TrList.includes(:status).search(params[:keyword]).sfilter(params[:status]).order(:updated_at).reverse_order.paginate(:page => params[:page], :per_page => 50)
    slim :tr
  end

  post '/tr' do
    body = request.body.read
    params= JSON.parse body
    if TrList.exists?(url: params['url'])
      return {
        warn: '重複',
        status: 'URL重複',
        title: params['name'],
        url: params['url'],
      }.to_json
    end
    ret=dl_tr(params['url'])
    columns={}
    columns[:url]=params['url']
    columns[:name]=ret[:code] || ret[:ename]
    columns[:rename]=ret[:jname] if ret[:jname]
    columns[:created_at]=ret[:utile] if ret[:utile]
    case ret[:action]
    when :site_err
      TrList.create(columns.merge({status_id: 2}))
      return {
        warn: 'エラー',
        status: 'Site_エラー:' + ret[:code],
        title: params['name'],
        url: params['url'],
      }.to_json
    when :no_name
      TrList.create(columns.merge({status_id: 4}))
      return {
        warn: 'エラー',
        status: '日本語タイトルなし',
        title: ret[:ename],
        url: params['url'],
      }.to_json
    when :dup
      TrList.create(columns.merge({status_id: 5}))
      return {
        warn: 'エラー',
        status: '重複タイトル',
        title: ret[:ename],
        url: params['url'],
      }.to_json
    when :ok
      TrList.create(columns.merge({status_id: 1}))
      return {
        status: '下戴',
        title: ret[:ename],
        url: params['url'],
      }.to_json
    end
  end

  post '/tr/:id/reload' do |id|
    page=TrList.find(id.to_i)
    #page=TrList.find(params['id'].to_i)
    ret=dl_tr(page.url)
    columns={}
    columns[:name]=ret[:code] || ret[:ename]
    columns[:rename]=ret[:jname] if ret[:jname]
    case ret[:action]
    when :site_err
      page.update(colums.merge({status_id: 2}))
      return {
        error:  'エラー',
        message: 'サイトエラー;'+ret[:code],
      }.to_json
    when :no_name
      page.update(colums.merge({status_id: 4}))
      return {
        error:  'エラー',
        message: '名前が無効:'+ret[:jname],
      }.to_json
    when :dup
      page.update(colums.merge({status_id: 5}))
      return {
        error:  'エラー',
        message: '同名ファイルがあるため更新だけ完了、ダウンロード未完了;'+ret[:jname],
        rename: ret[:jname]
      }.to_json
    when :ok
      page.update(colums.merge({status_id: 1}))
      return {
        message: '完了！'+ret[:jname],
        rename: ret[:jname]
      }.to_json
    end
    return {
      error:  'エラー',
      message: '不明なエラー！',
    }.to_json
  end

  get '/tr/:id' do |id|
    @statuses=Status.all
    @page=TrList.find(id.to_i)
    slim :tr_id
  end
  
  post '/tr/:id' do |id|
    @page=TrList.find(id.to_i)
    @statuses=Status.all
    colums={}
    colums[:name]  =params["name"]   if params["name"]   && params["name"].size >2
    colums[:rename]=params["rename"] if params["rename"] && params["rename"].size >2
    colums[:status_id]=params["status"].to_i
    @page.update(colums)

    if params["dl"]=='on' && (colums[:status_id]==4 ||colums[:status_id]==5 )&& params["rename"].size >5
      ret=dl_tr(@page.url,@page.rename)
      page=@page
      case ret[:action]
      when :site_err
        page.update({
          name: ret[:code],
          status_id: 2,
        })
      when :no_name
        page.update({status_id: 4})
      when :dup
        page.update({status_id: 5})
      when :ok
        page.update({status_id: 1})
      end
    end
    slim :tr_id
  end

  delete '/tr/:id' do
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

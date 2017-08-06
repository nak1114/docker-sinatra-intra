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

  post '/tr' do
    ActiveRecord::Base.connection_pool.with_connection do
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
      case ret[:action]
      when :site_err
        TrList.create({
          url: params['url'],
          name: ret[:code],
          status_id: 2,
        })
        return {
          warn: 'エラー',
          status: 'Site_エラー:' + ret[:code],
          title: params['name'],
          url: params['url'],
        }.to_json
      when :no_name
        TrList.create({
          url: params['url'],
          name: ret[:ename],
          status_id: 4,
          created_at: ret[:utime],
        })
        return {
          warn: 'エラー',
          status: '日本語タイトルなし',
          title: ret[:ename],
          url: params['url'],
        }.to_json
      when :dup
        TrList.create({
          url: params['url'],
          name: ret[:ename],
          rename: ret[:jname],
          status_id: 5,
          created_at: ret[:utime],
        })
        return {
          warn: 'エラー',
          status: '重複タイトル',
          title: ret[:ename],
          url: params['url'],
        }.to_json
      when :ok
        TrList.create({
          url: params['url'],
          name: ret[:ename],
          rename: ret[:jname],
          status_id: 1,
          created_at: ret[:utime],
        })
        return {
          status: '下戴',
          title: ret[:ename],
          url: params['url'],
        }.to_json
      end
    end
  end

  end

  put '/tr/:id' do
    ActiveRecord::Base.connection_pool.with_connection do
      body = request.body.read
      json = JSON.parse body
      pp params
      pp json
      page=TrList.find(params['id'].to_i)
      json['url']
      ret=dl_tr(json['url'],json['name'])
      case ret[:action]
      when :site_err
        return {
          error:  'エラー',
          message: 'サイトエラー;'+ret[:code],
        }.to_json
      when :no_name
        return {
          error:  'エラー',
          message: '名前が無効:'+ret[:jname],
        }.to_json
      when :dup
        page.update({
          rename: ret[:jname],
        })
        return {
          error:  'エラー',
          message: '同名ファイルがあるため更新だけ完了、ダウンロード未完了;'+ret[:jname],
          rename: ret[:jname]
        }.to_json
      when :ok
        page.update({
          rename: ret[:jname],
          status_id: 1,
        })
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

  get '/tr' do
    #@pages=TrList.all.limit(10)
    ActiveRecord::Base.connection_pool.with_connection do
      @statuses=Status.all
      @pages=TrList.includes(:status).search(params[:keyword]).sfilter(params[:status]).order(:updated_at).reverse_order.paginate(:page => params[:page], :per_page => 5)
      slim :tr
    end
  end

end
__END__

# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'will_paginate/view_helpers/sinatra'
require 'will_paginate/active_record'

require_relative '../helpers/product_helpers'
module MyAppRoute
end
class MyAppRoute::Product < Sinatra::Base
  configure do
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

  def link_to(obj, txt=nil)
    url=obj
    url="#{request.path_info}/#{obj.id}" if obj.class!=String
    txt||=url
    "<a href='#{url}'>#{txt}</a>"
  end

  get '/pdf' do
    #@pages=TrList.all.limit(10)
    ActiveRecord::Base.connection_pool.with_connection do
      @statuses=Status.all
      @pages=Product.includes(:status).search(params[:keyword]).sfilter(params[:status]).order(:updated_at).reverse_order.paginate(:page => params[:page], :per_page => 5)
      slim :pdf
    end
  end

  post '/pdf' do
    body = request.body.read
    params= JSON.parse body
    #ActiveRecord::Base.connection.close
    ActiveRecord::Base.connection_pool.with_connection do
      if Product.exists?(url: params['url'])
        return {
          warn: '重複',
          status: 'URL重複',
          title: params['name'],
          url: params['url'],
        }.to_json
      end
      name=params['name'].gsub(/[[:cntrl:]]/, '').to_fname.strip
      #name=params['name'].to_fname

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
  end
end

__END__

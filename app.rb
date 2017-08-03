#!ruby -Ku
# -*- coding: utf-8 -*-

require 'rubygems'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/activerecord'
require 'will_paginate/view_helpers/sinatra'
require 'will_paginate/active_record'
require 'sinatra-websocket'

require 'json'
require 'uri'

require 'net/http'
require 'fileutils'

require 'openssl'
require 'mechanize'
require 'bencode'

require_relative './models/product'
require_relative './models/tr_list'
require_relative './models/status'

require_relative './helpers/html_helpers'
require_relative './helpers/home_helpers'
require_relative './helpers/tr_list_helpers'
require_relative './helpers/product_helpers'

require_relative './routes/product_routes'
require_relative './routes/tr_list_routes'
require_relative './routes/home_routes'

require 'pp'

class String
  Tr_src="\\\\/:*?\"<>|\t"
  Tr_dst=%(￥／：＊？”＜＞｜)+" "
  def cut_byte(len=225)
    pstr=self
    while pstr.bytesize >len
      pstr=pstr[0..-2]
    end
    return pstr
  end
  def to_fname
    self.tr(Tr_src,Tr_dst)
  end
end


class MyApp < Sinatra::Base

  configure do
    set :server, :thin
    set :bind, '0.0.0.0'
    set :port, 3000
    
    use MyAppRoute::Product
    use MyAppRoute::TrList
    use MyAppRoute::Home

    register Sinatra::ActiveRecordExtension
    register Sinatra::CrossOrigin

    enable :cross_origin
    set :allow_origin, :any
    set :allow_methods, [:get, :post, :options]

    enable :method_override
  end
  configure :development do
    register Sinatra::Reloader
    
    also_reload '/myapp/helpers/*.rb'
    also_reload '/myapp/models/*.rb'
  end
  

  
  get '/test' do
    pp settings.development?
    "ret ok"
  end

end

if $0 == __FILE__
  MyApp.run!
end

__END__

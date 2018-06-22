# -*- coding: utf-8 -*-
class Status < ActiveRecord::Base
  has_many :putducts
  has_many :tv_lists
end

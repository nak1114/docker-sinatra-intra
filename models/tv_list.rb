# -*- coding: utf-8 -*-
class TvList < ActiveRecord::Base
  belongs_to :status
  
  def self.sfilter(status)
    return all unless status
    where(status_id: status)
  end
  def sname
    self.status.name
  end

end

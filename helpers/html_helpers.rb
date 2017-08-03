# -*- coding: utf-8 -*-
module MyAppHelper
end
module MyAppHelper::HTML

  def link_to(obj, txt=nil)
    url=obj
    url="#{request.path_info}/#{obj.id}" if obj.class!=String
    txt||=url
    "<a href='#{url}'>#{txt}</a>"
  end

end

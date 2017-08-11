# -*- coding: utf-8 -*-
module MyAppHelper
end
module MyAppHelper::Product
  Tlogin ="#{ENV['DL_SITE']}/webapi/auth.cgi?api=SYNO.API.Auth&version=2&method=login&account=#{ENV['DL_USERNAME']}&passwd=#{ENV['DL_PASSWORD']}&session=DownloadStation&format=sid"
  Tlogout="#{ENV['DL_SITE']}/webapi/auth.cgi?api=SYNO.API.Auth&version=2&method=logout&session=DownloadStation&sid="
  Purl   ="#{ENV['DL_SITE']}/webapi/DownloadStation/task.cgi"
  Dest_base="public/dl/pdf/"
  Pdf_dir='/dl/pdf/'
  def dl(url,name)
    browser = Mechanize.new
    browser.user_agent_alias = 'Windows IE 9'
    pg=browser.get(url)
    dl_url=pg.at('meta[name="twitter:image:src"]')[:content].sub(%r![^/]+\z!,'item.zip')

    ppara={api: "SYNO.DownloadStation.Task",
           version: "3",
           method: "create",
          }
    FileUtils.mkdir_p(Pdf_dir+name)
    res = Net::HTTP.get(URI.parse(Tlogin))

    sidb=JSON.parse(res)
    sid=sidb["data"]["sid"]

    ppara["uri"]=dl_url
    ppara["destination"]=Dest_base+name
    ppara["_sid"]=sid

    pres= Net::HTTP.post_form(URI.parse(Purl),ppara)

    res = Net::HTTP.get(URI.parse(Tlogout+sid))

    ret=JSON.parse(pres.body).merge({action: :registed})
    return ret if ret['success']
    return ret.merge({message: 'StationError'})
  rescue Mechanize::ResponseCodeError => e
    return {action: :site_err,code: e.response_code, message: 'SiteError:'+e.response_code}
  end

end

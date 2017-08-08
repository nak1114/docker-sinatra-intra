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
    ppara={api: "SYNO.DownloadStation.Task",
           version: "3",
           method: "create",
          }
    FileUtils.mkdir_p(Pdf_dir+name)
    res = Net::HTTP.get(URI.parse(Tlogin))

    sidb=JSON.parse(res)
    sid=sidb["data"]["sid"]

    #ppara["uri"]=url.sub('/item/','/item/dl_zip/')

    ppara["uri"]=url.sub('http://','http://item2.').sub('/item/','/')+'/item.zip'
    ppara["destination"]=Dest_base+name
    ppara["_sid"]=sid

    pres= Net::HTTP.post_form(URI.parse(Purl),ppara)

    res = Net::HTTP.get(URI.parse(Tlogout+sid))

    JSON.parse(pres.body)
    #{"success": true}
  end

end

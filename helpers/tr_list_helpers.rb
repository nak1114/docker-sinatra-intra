# -*- coding: utf-8 -*-
module MyAppHelper
end
module MyAppHelper::TrList
  Tr_cookie_path = '/myapp/Tr_cookie.yaml'
  Tr_username=ENV['TR_USERNAME']
  Tr_password=ENV['TR_PASSWORD']
  Tr_dir='/dl/tr/'
  @@sender_mutex=Mutex.new

  def senddata(message,type)
    data={
      action: "add",
      body: %Q!<p class="#{type}">#{message[:status]} : #{message[:title]}</p>!,
      count: settings.thread_counter,
    }
    @@sender_mutex.synchronize {
      settings.sockets.each do |s|
        s.send(data.to_json)
      end
    }
  end
  def info(message)
    senddata(message,"info")
  end
  def debug(message)
    senddata(message,"debug")
  end
  def error(message)
    senddata(message,"error")
  end

  def dl_tr(url,name='')
    browser = Mechanize.new
    browser.user_agent_alias = 'Windows IE 11'
    browser.verify_mode = OpenSSL::SSL::VERIFY_NONE
    browser.cookie_jar.load Tr_cookie_path if File.exist? Tr_cookie_path
      pg=browser.get(url)

    ename=pg.search('#info h1').text
    jname=pg.search('#info h2').text
    utime=pg.at('time')[:datetime]
    jname=name if name.size > 4
    ret={
      ename: ename,
      jname: jname,
      utime: DateTime.parse(utime),
    }

    if( jname.size < 5)
      return {action: :no_name}.merge(ret)
    end
    unless name
      if TrList.where(rename: jname).exists?
        return {action: :dup}.merge(ret)
      end
    end
    
    sleep(0.5)
    dd=pg.link_with(id: 'download')||pg.link_with(id: 'download-torrent')
    dl=dd.click
    if(dl.uri.path == '/login/')then
      f = dl.forms[0]
      f.field_with( :name => "username_or_email").value= Tr_username
      f.field_with( :name => "password").value= Tr_password
      sleep(0.5)
      dl = f.submit
      browser.cookie_jar.save_as Tr_cookie_path
      sleep(0.5)
      dd=pg.link_with(id: 'download')||pg.link_with(id: 'download-torrent')
      dl=dd.click
    end
    
    pstr=jname.to_fname.cut_byte
    # pname=dir+pstr.encode(Encoding::WINDOWS_31J   ,:replace => '□',:undef => :replace,:invalid => :replace)+'.torrent'
    pname=Tr_dir+pstr+'.torrent'
    bbb= BEncode::Parser.new(dl.body).parse!
    bbb['info']['name']=pstr.force_encoding("ascii-8bit")
    
    if File.exist?(pname) then
      return {action: :dup}.merge(ret)
    end
    File.binwrite(pname,bbb.bencode)
    return {action: :ok}.merge(ret)
  rescue Mechanize::ResponseCodeError => e
    return {action: :site_err,code: e.response_code}
  end
end


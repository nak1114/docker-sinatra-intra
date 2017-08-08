# -*- coding: utf-8 -*-
require 'fileutils'

module MyAppHelper
end
module MyAppHelper::Home
  Cmn_dest_dir = "/dl/_date/"
  Tr_glob_dir  = "/dl/dl/"
  Tr_pdftool   ='/dl/script/pdfimages -j '
  Tr_ziptool   ='zip -0 -r'
  Pdf_glob_dir  = "/dl/pdf/"

  @@dirinfo={}

  def get_dirinfo
    t=Dir.glob(Cmn_dest_dir+"*/").sort.reverse[0...15].map{|v| {dir: v[/\/([^\/]+)\/\z/,1],count: Dir.glob(v+'*.zip').count}}
    @@dirinfo[:action]='dirinfo'
    @@dirinfo[:trcur]=t.index{|v| /\d\z/.match?(v[:dir])}||0
    @@dirinfo[:pdfcur]=t.index{|v| /_pdf\z/.match?(v[:dir])}||0
    @@dirinfo[:data]=t
    @@dirinfo[:trcount]=Dir.glob(Tr_glob_dir+"*/").count
    @@dirinfo[:pdfcount]=Dir.glob(Pdf_glob_dir+"*/").count
    @@dirinfo
  end

  def tr2zip(mutex,messages,arg)
    if arg["dir"]==nil || arg["dir"]==""
      mutex.synchronize {
        settings.sockets.each do |s|
          s.send([{action: 'err',message: 'dir invalid'}].to_json)
        end
      }
      return
    end
    glob_name = Tr_glob_dir+"*/"
    glob_reg  = %r!\A.*/([^/]+)/\z!
    dest_dir=Cmn_dest_dir+arg["dir"]+"/"

    data=[{
      action: 'tr',
        total: 30,
        complete: 0
    }]
    ary=Dir.glob(glob_name)
    data[0][:total]=ary.size
    mutex.synchronize {
      messages[0]=data[0]
    }
    
    FileUtils.mkdir_p(dest_dir)

    ary.each.with_index do |fname,idx|
      data[0][:complete]=idx
      senddata=data.to_json
      mutex.synchronize {
        settings.sockets.each do |s|
          s.send(senddata)
        end
      }
      dst= dest_dir+fname.sub(glob_reg,'\1')+'.zip'
      next if File.exist?(dst)
      ret=false
      Dir.chdir(fname) do
        ret=system("#{Tr_ziptool} \"#{dst}\" .")
      end
      FileUtils.rm_rf(fname) if ret
    end
    data[0][:complete]=data[0][:total]
    senddata=data.to_json
    mutex.synchronize {
      settings.sockets.each do |s|
        s.send(senddata)
      end
      messages[0]=nil
    }
  rescue => e
    messages[0]=nil
    puts e.message
  end

  def zip2zip(mutex,messages,arg)
    if arg["dir"]==nil || arg["dir"]==""
      mutex.synchronize {
        settings.sockets.each do |s|
          s.send([{action: 'err',message: 'dir invalid'}].to_json)
        end
      }
      return
    end
    glob_name = Pdf_glob_dir+"*/*.zip"
    glob_reg  = Regexp.new("^#{Pdf_glob_dir}(.*)/[^/]*.zip$")
    dest_dir=Cmn_dest_dir+arg["dir"]+"/"

    data=[{
      action: 'pdf',
        total: 30,
        complete: 0
    }]
    ary=Dir.glob(glob_name)
    data[0][:total]=ary.size
    mutex.synchronize {
      messages[1]=data[0]
    }

    FileUtils.mkdir_p(dest_dir)

    ary.each.with_index  do |fname,idx|
      data[0][:complete]=idx
      senddata=data.to_json
      mutex.synchronize {
        settings.sockets.each do |s|
          s.send(senddata)
        end
      }
      #puts fname
      name=fname.sub(glob_reg,'\1')
      dst="#{dest_dir}#{name}.zip"
      dir=File.dirname(fname)

      if name[0]=='_'
        puts "illigal #{dst}"
        next
      end

      if File.exist?(dst)
        puts "skip #{dst}"
        next
      end
      
      FileUtils.mv(fname,dst)
      gg=dir.sub('[','\\[')+'/*'
      if Dir.glob(gg).size == 0
        FileUtils.rm_rf(dir)
      end

    end
    data[0][:complete]=data[0][:total]
    senddata=data.to_json
    mutex.synchronize {
      settings.sockets.each do |s|
        s.send(senddata)
      end
      messages[1]=nil
    }
  rescue => e
    messages[1]=nil
    puts e.message
  end

end

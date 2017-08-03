# -*- coding: utf-8 -*-
require 'fileutils'

module MyAppHelper
end
module MyAppHelper::Home
  Tr_glob_dir  = "/dl/dl/"
  Tr_dest_dir  ='/dl/zip/tr/'
  Tr_pdftool   ='/dl/script/pdfimages -j '
  Tr_ziptool   ='zip -0 -r'

  def tr2zip(mutex,messages)
    glob_name = Tr_glob_dir+"*/"
    glob_reg  = %r!\A.*/([^/]+)/\z!
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

    ary.each.with_index do |fname,idx|
      data[0][:complete]=idx
      senddata=data.to_json
      mutex.synchronize {
        settings.sockets.each do |s|
          s.send(senddata)
        end
      }
      dst= Tr_dest_dir+fname.sub(glob_reg,'\1')+'.zip'
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
      messages[1]=nil
    }
  rescue => e
    messages[1]=nil
    puts e.message
  end

  Pdf_glob_dir  = "/dl/pdf/"
  Pdf_dest_dir  ='/dl/zip/pdf/'

  def zip2zip(mutex,messages)
    glob_name = Pdf_glob_dir+"*/*.zip"
    glob_reg  = Regexp.new("^#{Pdf_glob_dir}(.*)/[^/]*.zip$")

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
      dst="#{Pdf_dest_dir}#{name}.zip"
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

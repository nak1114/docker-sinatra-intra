# -*- coding: utf-8 -*-

require_relative 'shoboi_renamer'

module MyAppHelper
end
module MyAppHelper::TvList
  SortedDir=%q'/unsort/aaa/' #to
  UnsortDir=%q'/unsort/' #from
  RenameDir=%q'/unsort/_comp/_end/_move/'
  AppendDir=["_その他","_その他/単発/アニメ1話","_その他/単発/単発・アニメ","_その他/単発/単発・教養","_その他/単発/単発・ドラマ","_その他/単発/分類不能"]
  
  ServiceName={
    "BSジャパン" => "BS Japan" ,
    "NHKBSプレミアム" => "NHK BSプレミアム",
    "BSフジ・181" => "BSフジ",
    "NHK総合・東京"=> "NHK総合",
    "NHKEテレ東京" => "NHK Eテレ",
    "BS11イレブン" => "BS11デジタル",
    "BS朝日1" => "BS朝日",
    "フジテレビジョン" => "フジテレビ",
  }
  @@sender_mutex=Mutex.new
  @@thread_mutex=Mutex.new

  def tv_flist
    list=Dir.glob(UnsortDir+'*.ts')
    if params[:sort]
      list=list.sort
    else
      list=list.sort_by{|v| File::Stat.new(v).mtime}.reverse
    end
    list=list.map{|v| File.basename(v,".ts")}
    list
  end

  def senddata(message,type)
    data={
      action: "add",
      body: %Q!<p class="#{type}">#{message.gsub(/\n/,"<br/>")}</p>!
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

  def add_lists(flist)
    flist.each do |v|
      dir_name=v
          .sub(/[　 \r\n\t]*(\[.*\]_第\d+話.*)?$/,'')
          .sub(/^[　 \r\n\t]*/,'').strip 
      columns={}
      columns[:name]=dir_name
      TvList.create(columns.merge({status_id: 4}))
    end
  end

  def sort_files(flist,isFinalCheck)
    return if @@thread_mutex.locked?
    @@thread_mutex.synchronize{
      sleep 1
      dirs=TvList.where(status_id: 4).order(updated_at: :desc)
      dir_names=dirs.map{|v| v.name}
  
      Dir.glob(UnsortDir+'*.ts').each do |filename|
        basename=File.basename(filename,".ts")
        next if flist.include? basename
        basename=basename.sub(/[　 \r\n\t]*\[.*\]_第\d+話.*$/,'')
        score,dirname=dir_names.inject([0.5,nil])do|ret,dirname|
          score=Levenshtein.normalized_distance(basename,dirname)
          (score<ret[0]) ? [score,dirname] : ret
        end
        mes="#{score}　【#{dirname}】　#{filename}"
        if dirname then
          path=SortedDir+dirname
          Dir.mkdir(path) unless Dir.exist?(path)
          begin
            FileUtils.mv(filename,path)
            FileUtils.rm(filename+'.meta') if File.exist?(filename+'.meta')
            info mes
          rescue => e
            error "#{e.message}:#{filename}"
          end
        else
          debug mes
        end
      end
      if isFinalCheck
        check_final(dirs)
      end
      info "完了！"
    }
  end

  def is_stableDir(path)
    curTime =Time.now - (10*24*60*60)
    return Dir.glob(path+'/*.ts').reduce(true) do |flg,item|
      flg && (curTime > File::Stat.new(item).mtime)
    end
  end

  def renamer
    @renamer||=ShoboiRenamer.new(ServiceName,self)
    @renamer
  end

  def check_final(dirs)
    dirs.each do |dir|
      dirname=dir.name
      path=SortedDir+dirname
      mv_dirname=RenameDir+dirname
      if Dir.exist?(path)
        if is_stableDir(path)
          info "最終回\t#{dirname}"
          if Dir.exist?(mv_dirname)
            info "Already exist\t#{mv_dirname}"
          else
            renamer.rename_title(path)
            FileUtils.mv(path,mv_dirname)
            dir.update({status_id: 1})
            #moved << "#{Time.now}\t#{current.pop}"
          end
        end
      else
        info "移動済\t#{dirname}"
        dir.update({status_id: 2})
        #moved << "#{Time.now}\t#{current.pop}"
      end
    end
  end

end


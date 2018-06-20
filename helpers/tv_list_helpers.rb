# -*- coding: utf-8 -*-
module MyAppHelper
end
module MyAppHelper::TvList
  SortedDir=%q'/sort/' #to
  UnsortDir=%q'/unsort/' #from
  RenameDir=%q'/renamed/'

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

  def tv_sort(flist)
    dir_names=TvList.where(status_id: 2).order(updated_at: :desc).map{|v| v.name}
    Dir.glob(UnsortDir+'*.ts').each do |filename|
      basename=File.basename(filename,".ts")
      next if flist.include? basename
      basename=basename.sub(/[　 \r\n\t]*\[.*\]_第\d+話.*$/,'')
      score,dirname=dir_names.inject([0.5,nil])do|ret,dirname|
        score=Levenshtein.normalized_distance(basename,dirname)
        (score<ret[0]) ? [score,dirname] : ret
      end
      mes="#{score}\t#{dirname}\t#{filename}"
      if dirname then
        path=SortedDir+dirname
        Dir.mkdir(path) unless Dir.exist?(path)
        begin
          FileUtils.mv(filename,path)
          FileUtils.rm(filename+'.meta') if File.exist?(filename+'.meta')
          puts mes
        rescue => e
          puts "#{e.message}:#{filename}"
        end
      end
    end
  end
end


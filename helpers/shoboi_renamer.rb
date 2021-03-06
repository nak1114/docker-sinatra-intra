#!ruby
# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'
require 'ariblib'
require 'logger'
require 'open-uri'
require 'rexml/document'

class String
  def to_file
    tr_src=%(¥/:*?"<>|!)
    tr_dst=%(￥／：＊？”＜＞｜！)
    self.tr( tr_src,tr_dst)
  end
end

class ShoboiRenamer
  FlgRename=true
  RecMargin=Rational(2,24*60)

  def initialize(local=nil,logger=nil)
    @logger = logger
    @ChID=get_ch
    @ServiceName=Hash.new{|h,k| h[k]=k}
    @ServiceName.merge!(local) if local
    @Cache={}
  end
  
  def curl(url)
    doc=REXML::Document.new(open(url).read)
    sleep 1
    doc
  end

  def get_ch
    doc=curl("http://cal.syoboi.jp/db.php?Command=ChLookup")
    h={}
    doc.each_element('/ChLookupResponse/ChItems/ChItem') do |v|
      name=v.text('./ChName')
      chid=v.text('./ChID')
      h[name]=chid.to_i
    end
    h
  end

  def error(str)
    @logger.error str if @logger
  end
  def info(str)
    @logger.info str if @logger
  end

  def parse_ts_file(fname)
    ts = Ariblib::TransportStreamFile.new(fname,{
      0x0014 => Ariblib::TimeOffsetTable.new,
      0x0010 => Ariblib::NetworkInformationTable.new,
      0x0011 => Ariblib::ServiceDescriptionTable.new})
    name=nil
    time=nil
    while(name==nil || time==nil) do
      if name==nil && ts.payload[0x11].contents.size > 0
        t=ts.payload[0x11].contents.shift
        if t[0][0]==0x42 && t.size > 0
          if t[1][1][:service_provider_name].size >0
            name=t[1][1][:service_name] #for BS
          end
        end
      end
      if name==nil && ts.payload[0x10].contents.size > 0
        t=ts.payload[0x10].contents.shift
        if t[0][1]==0x40 && t.size > 0
          name=t[1][2][:TS_name] #for 地上波
        end
      end
      if time==nil && ts.payload[0x14].contents.size > 0
        time=(ts.payload[0x14].to_datetime+RecMargin).strftime("%Y%m%d_%H%M00-%Y%m%d_%H%M01")
        ts.payload[0x14].contents.delete_at(0)
      end
      break unless ts.transport_packet
    end
    ts.close
    name = name.tr("０-９Ａ-Ｚａ-ｚ　", "0-9A-Za-z ") if name
    [name,time]
  end

  def rename_title(dir_name)
    Dir.glob(dir_name.gsub("\\",'/')+'/*.ts') do |fname|
      name,time=parse_ts_file(fname)

#      ch=fname[/\[(.*?)\]/ , 1]
      ch=@ServiceName[name]
      dis=@ChID[ch]
      unless dis
        error "Can't get program service data."+
            " file:#{fname}\n"+
            "name:#{name}"
        next
      end
      q1="http://cal.syoboi.jp/db.php?Command=ProgLookup&ChID=#{dis}&Range=#{time}&JOIN=SubTitles"
      doc=curl(q1)
      response=doc.elements['/ProgLookupResponse/Result/Code'].text.to_i
      message =doc.elements['/ProgLookupResponse/Result/Message'].text
      if response != 200
        error "Can't get program data."+
            " file:#{fname}\n"+
            "query1:#{q1}"
        next
      end
      tid     =doc.elements['/ProgLookupResponse/ProgItems/ProgItem/TID'].text.to_i
      count   =doc.elements['/ProgLookupResponse/ProgItems/ProgItem/Count'].text.to_i
      subtitle=doc.elements['/ProgLookupResponse/ProgItems/ProgItem/STSubTitle'].text
      q2="http://cal.syoboi.jp/db.php?Command=TitleLookup&TID=#{tid}"
      doc = @Cache[tid] || curl(q2)
      response =doc.elements['/TitleLookupResponse/Result/Code'].text.to_i
      message  =doc.elements['/TitleLookupResponse/Result/Message'].text
      if response != 200
        error "Can't get subtitle data.\n"+
          " file:#{fname}\n"+
          "count:#{count}\n"+
          "query1:#{q1}\n"+
          "query2:#{q2}"
        next
      end
      @Cache[tid] = doc unless @Cache[tid]
      title    =doc.elements['/TitleLookupResponse/TitleItems/TitleItem/Title'].text
      subtitles=doc.elements['/TitleLookupResponse/TitleItems/TitleItem/SubTitles'].text || ""
      stitle   =subtitles.scan(/\*0*(\d+)\*([^\n]+)/).assoc(count.to_s)
      unless stitle
        error "***not found***\n"+
          "file:#{fname}\n"+
          "subtitles:#{subtitles}\n"+
          "count:#{count}\n"+
          "query1:#{q1}\n"+
          "query2:#{q2}"
        next
      end
      filebody="#{title} [#{ch}]_第#{format('%02d',count)}話 「#{stitle[1]}」".to_file.cut_byte
      str="#{File.dirname(fname)}/#{filebody}.ts"
      if FlgRename and not File.exist?(str)
        info "renamed:\nsrc:#{fname}\ndst:#{str}"
        File.rename(fname,str)
      else
        info "ooooops:\nsrc:#{fname}\ndst:#{str}"
      end
    end
  end
end
if $0 == __FILE__
  require 'pp'
  pp ShoboiRenamer.new.get_ch
end


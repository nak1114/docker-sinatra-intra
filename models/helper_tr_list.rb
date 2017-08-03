#!ruby -Ku
# -*- coding: utf-8 -*-


require 'active_record'
require 'csv'

ActiveRecord::Base.configurations = YAML.load_file('./config/database.yml')
ActiveRecord::Base.establish_connection(:development)

require_relative '../models/tr_list'
require_relative '../models/status'

StList={
  'JP'=>1,
  'EN'=>4,
  'DP'=>5,
  'PD'=>3,
  'NG'=>2,
}


def import_tsv( file_name, class_name )
  puts "import #{class_name.to_s}"

  quote_chars = %w(" | ~ ^ & *)
  begin
    index=0
    class_name.delete_all
    ActiveRecord::Base.connection.execute('ALTER TABLE `tr_lists` AUTO_INCREMENT = 1')
    open(file_name,'r:utf-8') do |f|
      f.each_line do |l|
        row=l.chop.split("\t")
        index+=1
        st=StList[row[0]]
        unless st
          p [index,row]
          next
        end
        record = class_name.new
        record.url=row[1] if row[1] && row[1].size>1
        record.name=row[3]||""
        record.status_id=st
        record.rename=row[4] if row[4] && row[4].size>1
        record.created_at= DateTime.parse(row[2]) if row[2]
        record.save
        p index if (index % 10)==0
      end
    end
  end
end

import_tsv('./models/convert_log.txt',TrList)

require 'active_record'
require 'csv'

ActiveRecord::Base.configurations = YAML.load_file('./config/database.yml')
ActiveRecord::Base.establish_connection(:development)

require_relative '../models/product'
require_relative '../models/status'




def import_tsv( file_name, class_name )
  puts "import #{class_name.to_s}"

  quote_chars = %w(" | ~ ^ & *)
  begin
    index=0
    class_name.delete_all
    CSV.foreach(file_name,  col_sep: "\t", quote_char: quote_chars.shift) do |row|
      row.unshift index+=1
      record = class_name.new
      record.attributes.keys.each do |key|
        p [key,row[0]]
        record[key] = "#{row.shift}"
      end
      record.save(:validate => false)
    end
  rescue CSV::MalformedCSVError
    quote_chars.empty? ? raise : retry
  end
end

Product.delete_all
import_tsv('./models/status.tsv',Status)
import_tsv('./models/dbtv.txt',Product)

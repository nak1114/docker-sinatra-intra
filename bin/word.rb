require 'active_record'

table={
'-s'=> :singularize,
'-p'=> :pluralize,
'-c'=> :classify,
'-t'=> :tableize,
'-C'=> :camelcase,
'-F'=> :underscore,
}

method=table[ARGV[0]]
ARGV.shift if method
method||=:pluralize
ARGV.each do |v|
  puts v.send(method)
end
__END__

require 'yaml'

dir = ARGV[0]
compiled = {}
IO.readlines( dir + '/generated.csv')[1..-1].each do |line|
  line = line.split( "\t")
  compiled[line[0]] = line[1]
end

YAML.load( IO.read( dir + '/to_check.yaml'))['pages'].each do |page|
  command = <<COMMAND
cp #{compiled[page['original']]} #{dir}/golden_files/#{page['golden']}
COMMAND
  unless system( command)
    raise "*** #{command}"
  end
end

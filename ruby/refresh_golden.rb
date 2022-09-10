require 'yaml'

YAML.load( IO.read( ARGV[0]))['pages'].each do |page|
  command = <<COMMAND
cp #{page['compiled']} #{ARGV[1]}/#{page['golden']}
COMMAND
  unless system( command)
    raise "*** #{command}"
  end
end

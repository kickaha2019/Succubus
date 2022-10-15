require 'yaml'

dir = ARGV[0]
compiled = {}
YAML.load( IO.read( dir + '/generation.yaml')).each_pair do |url, info|
  next unless info['output'].is_a?( Array)
  next if info['output'].empty?
  compiled[url] = ARGV[1] + info['output'][0].gsub( /_index\.md$/, 'index.md').gsub( /\.md$/, '.html')
end

YAML.load( IO.read( dir + '/to_check.yaml'))['pages'].each do |page|
  command = <<COMMAND
cp #{compiled[page['original']]} #{dir}/golden_files/#{page['golden']}
COMMAND
  unless system( command)
    raise "*** #{command}"
  end
end

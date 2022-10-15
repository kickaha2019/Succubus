require 'yaml'

dir = ARGV[0]
compiled = {}
YAML.load( IO.read( dir + '/generation.yaml')).each_pair do |url, info|
  next unless info['output'].is_a?( Array)
  next if info['output'].empty?
  compiled[url] = ARGV[1] + info['output'][0].gsub( /_index\.md$/, 'index.md').gsub( /\.md$/, '.html')
end

File.open( ARGV[2], 'w') do |io|
  io.puts <<"HEADER"
<html><head>
<style>
div {display: flex; justify-content: center}
table {border-spacing: 0px; border-collapse: collapse}
th, td {padding: 5px; border-style: solid;
        border-width: 1px; border-color: black;
        font-size: 20px}
</style>
</head>
<body><div><table><tr>
<th>Title</th>
<th>Original</th>
<th>Compiled</th>
<th>Comment</th>
</tr>
HEADER
  YAML.load( IO.read( dir + '/to_check.yaml'))['pages'].each do |page|
    colour  = 'lime'
    comment = page['features']
    golden  = dir + '/golden_files/' + page['golden']
    got     = compiled[page['original']]

    if got
      if File.exist?( golden)
        if File.exist?( got)
          unless IO.read( golden) == IO.read( got)
            colour = 'red'
            comment = "diff #{got} #{golden}"
          end
        else
          p ['to_check', got]
          colour = 'red'
          comment = "Compiled file missing"
        end
      end
    else
      colour = 'red'
      comment = "Unknown original"
    end

    io.puts <<"LINE"
<tr>
<td>#{page['title']}</td>
<td><a target="_blank" href="#{page['original']}">Original</a></td>
<td bgcolor="#{colour}"><a target="_blank" href="file://#{got}">Compiled</a></td>
<td>#{comment}</td>
</tr>
LINE
  end
  io.puts '</table></div></body></html>'
end

require 'yaml'

dir = ARGV[0]
compiled = {}
IO.readlines( dir + '/generated.csv')[1..-1].each do |line|
  line = line.split( "\t")
  compiled[line[0]] = line[1]
end

File.open( ARGV[1], 'w') do |io|
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

    got = got.sub( /\.md$/, '.html').sub( /_index\.html$/, 'index.html')
    unless /\/index\.html$/ =~ got
      got = got.sub( /\.html$/, '/index.html')
    end
    got = got.sub( 'Hugo/content', 'Hugo_public') # Perhaps use config setting?

    if got
      if File.exist?( golden)
        if File.exist?( got)
          unless IO.read( golden) == IO.read( got)
            colour = 'red'
            comment = "diff #{page['compiled']} #{golden}"
          end
        else
          p [got]
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

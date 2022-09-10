require 'yaml'

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
  YAML.load( IO.read( ARGV[0]))['pages'].each do |page|
    colour = 'lime'
    comment = page['features']
    golden = ARGV[1] + '/' + page['golden']
    if File.exist?( golden)
      unless IO.read( golden) == IO.read( page['compiled'])
        colour = 'red'
        comment = "diff #{page['compiled']} #{golden}"
      end
    end

    io.puts <<"LINE"
<tr>
<td>#{page['title']}</td>
<td><a target="_blank" href="#{page['original']}">Original</a></td>
<td bgcolor="#{colour}"><a target="_blank" href="file://#{page['compiled']}">Compiled</a></td>
<td>#{comment}</td>
</tr>
LINE
  end
  io.puts '</table></div></body></html>'
end

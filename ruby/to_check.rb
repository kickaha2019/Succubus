require 'yaml'

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
<th>Features</th>
</tr>
HEADER
  YAML.load( IO.read( ARGV[0]))['pages'].each do |page|
    io.puts <<"LINE"
<tr>
<td>#{page['title']}</td>
<td><a target="_blank" href="#{page['original']}">Original</a></td>
<td><a target="_blank" href="#{page['compiled']}">Compiled</a></td>
<td>#{page['features']}</td>
</tr>
LINE
  end
  io.puts '</table></div></body></html>'
end

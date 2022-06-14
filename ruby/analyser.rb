require 'nokogiri'
require 'yaml'

require_relative 'parser'

class Analyser
  @@indents = [' ', '|', '&boxur;', '&boxvr;']

  def initialize( config, cache)
    @config = config
    @cache  = cache
    @pages  = YAML.load( IO.read( @cache + '/grabbed.yaml'))
  end

  def dump( ts, filename)
    body = IO.read( "#{@cache}/#{ts}.html")
    html_doc = Nokogiri::HTML( body)
    struct   = Parser.new( @config).parse( html_doc.root.at_xpath( '//body'))

    File.open( filename, 'w') do |io|
      io.puts <<"DUMP1"
<html><head>
<style>
.indent {font-family: courier; font-size: 30px; width: 20px; height: 20px; display: inline-block;
         cursor: pointer}
.label {font-size: 20px; height: 20px}
.grokked {background: #D8D8D8}
</style>
<script>
function expand( index) {
  document.getElementById( 'e' + index).style.display = 'inline';
  document.getElementById( 'r' + index).style.display = 'none';
  document.getElementById( 'd' + index).style.display = 'block';
}
function reduce( index) {
  document.getElementById( 'e' + index).style.display = 'none';
  document.getElementById( 'r' + index).style.display = 'inline';
  document.getElementById( 'd' + index).style.display = 'none';
}
</script>
</head>
<body><div>
DUMP1
      dump_structure( struct, 0, io)
      io.puts <<"DUMP2"
<div><body></html>
DUMP2
    end
  end

  def dump_structure( struct, indent, io)
    if indent > 0
      (0...indent).each do
        io.print "<div class=\"indent\"></div>"
      end
    end

    io.print "<div class=\"indent\">"
    before, after = '', ''
    if struct.contents.size > 0
      io.print "<span id=\"r#{struct.index}\"#{struct.grokked? ? '' : ' style="display: none"'} onclick=\"expand(#{struct.index})\">&rtri;</span>"
      io.print "<span id=\"e#{struct.index}\"#{struct.grokked? ? ' style="display: none"' : ''} onclick=\"reduce(#{struct.index})\">&dtri;</span>"
      before = "<div id=\"d#{struct.index}\"#{struct.grokked? ? ' style="display: none"' : ''}>"
      after  = '</div>'
    end
    io.print "</div>"

    io.print "<span class=\"label#{struct.grokked? ? ' grokked' : ''}\">"
    io.print( struct.doc.name + ': ' + struct.describe)
    io.puts "</span><br>"

    io.puts before
    struct.contents.each do |child|
      dump_structure(  child, indent+1, io)
    end
    io.puts after
  end

  def report( dir)
    to_delete = []
    Dir.entries( dir).each do |f|
      to_delete << f if /\.html$/ =~ f
    end
    to_delete.each do |f|
      File.delete( "#{dir}/#{f}")
    end

    addresses = @pages.keys.sort
    File.open( dir + '/index.html', 'w') do |io|
      io.puts <<HEADER1
<html>
<head>
<style>
body {display: flex; align-items: center; flex-direction: column}
table {border-collapse: collapse}
td, th {border: 1px solid black; font-size: 30px}
</style>
</head>
<body><div><table><tr><th>Page</th><th>Login</th><th>Analysis</th><th>Comment</th><th>Timestamp</th></tr>
HEADER1
      addresses.each_index do |i|
        addr = addresses[i]
        next if @pages[addr]['timestamp'] == 0
        io.puts "<tr><td><a href=\"#{@cache}/#{@pages[addr]['timestamp']}.#{addr.split('.')[-1]}\">#{addr}</a></td>"
        io.puts "<td>#{@pages[addr]['secure'] ? 'Y' : ''}</td>"
        io.puts "<td><a href=\"#{i}.html\">Status?</a></td>"
        io.puts "<td>#{@pages[addr]['comment']}</td>"
        io.puts "<td>#{Time.at(@pages[addr]['timestamp']).strftime( '%Y-%m-%d')}</td></tr>"
        if File.exist?( dir + "/#{i}.html")
          begin
            dump( @pages[addr]['timestamp'], dir + "/#{i}.html")
          rescue
            puts "*** File: #{@pages[addr]['timestamp']}.html"
            raise
          end
        end
      end

      io.puts <<FOOTER
</table><div></body></html>
FOOTER
    end
  end
end

a = Analyser.new( ARGV[0], ARGV[1])
a.report( ARGV[2])

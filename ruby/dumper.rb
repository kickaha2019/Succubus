require 'yaml'

require_relative 'processor'

class Dumper < Processor
  def dump( struct, filename, debug=false)
    File.open( filename, 'w') do |io|
      io.puts <<"DUMP1"
<html><head>
<style>
.indent {font-family: courier; font-size: 30px; width: 20px; height: 20px; display: inline-block;
         cursor: pointer}
.label {font-size: 20px; height: 20px}
.grokked {background: lime}
.grokked_and_content {background: yellow}
.error {background: red}
.section {background: cyan}
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
      dump_structure( struct, 0, dump_expand( struct, debug), io)
      io.puts <<"DUMP2"
<div><body></html>
DUMP2
    end
  end

  def dump_expand( struct, debug=false)
    expand, focus = {}, {}
    struct.tree do |element|
      if element.error?
        focus[element.id] = true
      elsif element.is_a?( Elements::Article)
        focus[element.id] = true
      end
      p ['dump_expand1', element.id, focus[element.id]] if debug && focus[element.id]

      element.contents.each do |child|
        expand[element.id] = true if expand[child.id] || focus[child.id]
      end
    end

    if debug
      p ['dump_expand2', expand, focus]
    end

    expand
  end

  def dump_structure( struct, indent, expand, io)
    if indent > 0
      (0...indent).each do
        io.print "<div class=\"indent\"></div>"
      end
    end

    io.print "<div class=\"indent\">"
    before, after = '', ''
    exp = expand[struct.id]

    if struct.contents.size > 0
      io.print "<span id=\"r#{struct.id}\"#{exp ? ' style="display: none"' : ''} onclick=\"expand(#{struct.id})\">&rtri;</span>"
      io.print "<span id=\"e#{struct.id}\"#{exp ? '' : ' style="display: none"'} onclick=\"reduce(#{struct.id})\">&dtri;</span>"
      before = "<div id=\"d#{struct.id}\"#{exp ? '' : ' style="display: none"'}>"
      after  = '</div>'
    end
    io.print "</div>"

    scheme, tooltip = '', false, ''
    struct_error, tooltip = struct.error?

    if struct_error
      scheme = 'error'
    elsif struct.article?
      scheme = 'section'
    elsif struct.grokked?
      if struct.content?
        scheme = 'grokked_and_content'
      else
        scheme = 'grokked'
      end
    else
      if struct.content?
        scheme  = 'error'
        tooltip = 'Ungrokked content'
      end
    end

    # if struct.doc.name == 'nav'
    #   p [struct.doc.name, scheme, struct.class.name, struct.grokked?, struct.content?]
    # end

    io.print "<span class=\"label #{scheme}\" title=\"#{struct.tooltip}#{tooltip}\">"
    io.print( struct.describe)
    io.puts "</span><br>"

    io.puts before
    struct.contents.each do |child|
      dump_structure(  child, indent+1, expand, io)
    end
    io.puts after
  end

  def process( dir, counter, every)
    preparse_all

    pages do |url|
      debug = (url == @config['debug_url'])
      _, _, _, _, parsed = examine( url, debug)
      if parsed
        if counter == 0
          dump( parsed, dir + "/#{lookup(url).timestamp}.html", debug)
          counter = every - 1
        else
          counter -= 1
        end
      end
    end
  end
end

d = Dumper.new( ARGV[0], ARGV[1])
d.process( ARGV[2], ARGV[3].to_i, ARGV[4].to_i)

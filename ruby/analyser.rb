require 'yaml'

require_relative 'processor'

class Analyser < Processor
  @@indents = [' ', '|', '&boxur;', '&boxvr;']

  def close_files
    @files.each {|io| io.close}
  end

  def dump( struct, filename)
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
    expand = (struct.contains_article? && (! struct.article?)) || (! struct.grokked?)

    if struct.contents.size > 0
      io.print "<span id=\"r#{struct.index}\"#{expand ? ' style="display: none"' : ''} onclick=\"expand(#{struct.index})\">&rtri;</span>"
      io.print "<span id=\"e#{struct.index}\"#{expand ? '' : ' style="display: none"'} onclick=\"reduce(#{struct.index})\">&dtri;</span>"
      before = "<div id=\"d#{struct.index}\"#{expand ? '' : ' style="display: none"'}>"
      after  = '</div>'
    end
    io.print "</div>"

    scheme = ''
    if struct.error?
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
        scheme = 'error'
      end
    end

    # if struct.doc.name == 'nav'
    #   p [struct.doc.name, scheme, struct.class.name, struct.grokked?, struct.content?]
    # end

    io.print "<span class=\"label #{scheme}\" title=\"#{struct.tooltip}\">"
    io.print( struct.describe)
    io.puts "</span><br>"

    io.puts before
    struct.contents.each do |child|
      dump_structure(  child, indent+1, io)
    end
    io.puts after
  end

  def open_files( dir)
    @files = [
        File.open( dir + '/index.html', 'w'),
        File.open( dir + '/index1.html', 'w')
    ]
    @is_asset = false
  end

  def report( dir)
    preparse_all
    to_delete = []
    Dir.entries( dir).each do |f|
      to_delete << f if /\.html$/ =~ f
    end
    to_delete.each do |f|
      File.delete( "#{dir}/#{f}")
    end

    open_files( dir)

    addresses = @pages.keys.sort
    write_files <<HEADER1
<html>
<head>
<style>
body {display: flex; align-items: center; flex-direction: column; justify-content: center;}
table {border-collapse: collapse}
.pages td, .pages th {border: 1px solid black; font-size: 20px}
.menu {padding-bottom: 20px}
.menu td {font-size: 30px}
</style>
</head>
<body><div class="menu"><table><tr>
HEADER1

    @files[0].print "<td><a href=\"index1.html\">Hide assets</a><td>"
    @files[1].print "<td><a href=\"index.html\">Show assets</a><td>"

    write_files <<HEADER2
</tr></table></div><div class="pages"><table><tr>
<th>Page</th>
<th>State</th>
<th>Articles</th>
<th>Date</th>
<th>Tags</th>
<th>Comment</th>
<th>Timestamp</th>
</tr>
HEADER2

    addresses.each_index do |i|
      addr = addresses[i]
      @is_asset = asset?(addr)
      ts   = @pages[addr]['timestamp']
      ext  = @is_asset ? addr.split('.')[-1] : 'html'
      #next if ts == 0

      next if exclude_url?( addr)

      parsed = nil
      if File.exist?( @cache + "/#{ts}.html") && (ext == 'html')
        begin
          parsed = parse( addr, @pages[addr]['timestamp'])
        rescue
          puts "*** File: #{@pages[addr]['timestamp']}.html"
          raise
        end
      end

      if ts == 0
        write_files "<tr><td>#{addr}</td>"
      else
        write_files "<tr><td><a title=\"#{@pages[addr]['referral']}\" target=\"_blank\" href=\"#{@cache}/#{ts}.#{ext}\">#{addr}</a></td>"
      end

      if parsed
        error = parsed.content?
        parsed.tree {|child| error = true if child.error?}
        write_files "<th bgcolor=\"#{error ? 'red' : 'lime'}\">"
        write_files "<a target=\"_blank\" href=\"#{i}.html\">"
        write_files( error ? '&cross;' : (@pages[addr]['secure'] ? '&timesb;' : '&check;'))
        write_files "</a></th>"
      elsif @pages[addr]['redirect']
        write_files "<th bgcolor=\"lime\">&rArr;</th>"
      elsif ts == 0
        write_files "<th bgcolor=\"yellow\">?</th>"
      elsif asset?(addr)
        write_files "<th bgcolor=\"lime\">&check;</th>"
      else
        write_files "<th bgcolor=\"red\">&cross;</th>"
      end

      n_articles, date, tags = 0, '', ''
      if parsed
        parsed.tree do |child|
          if child.is_a?( Elements::Article)
            n_articles += 1
            if child.date
              date = child.date.strftime( '%Y-%m-%d')
            end
            if child.tags
              tags = child.tags.collect {|tag| tag[1]}.join( ' ')
            end
          end
        end
      end

      write_files "<td>#{n_articles}</td>"
      write_files "<td>#{date}</td>"
      write_files "<td>#{tags}</td>"
      write_files "<td>#{@pages[addr]['comment']}</td>"

      if ts == 0
        write_files "<td></td></tr>"
      else
        write_files "<td>#{Time.at(ts).strftime( '%Y-%m-%d')}</td></tr>"
      end

      if parsed
        dump( parsed, dir + "/#{i}.html")
      end
    end

    @is_asset = false
    write_files <<FOOTER
</table><div></body></html>
FOOTER

    close_files
  end

  def write_files( text)
    @files[0].print text
    @files[1].print text unless @is_asset
  end
end

a = Analyser.new( ARGV[0], ARGV[1])
a.report( ARGV[2])

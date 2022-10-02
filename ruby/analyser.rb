require 'yaml'

require_relative 'processor'

class Analyser < Processor
  @@indents = [' ', '|', '&boxur;', '&boxvr;']

  def close_files
    @files.each {|io| io.close}
  end

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

  def open_files( dir)
    @files = [
        File.open( dir + '/index.html',  'w'),
        File.open( dir + '/index1.html', 'w'),
        File.open( dir + '/index2.html', 'w'),
        File.open( dir + '/index3.html', 'w'),
        File.open( dir + '/index4.html', 'w'),
        File.open( dir + '/index5.html', 'w'),
        File.open( dir + '/index6.html', 'w'),
        File.open( dir + '/index7.html', 'w')
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
    n_all, n_articles, n_break, n_error, n_secure, n_redirect, n_asset, n_grabbed = 0, 0, 0, 0, 0, 0, 0, 0

    addresses     = @pages.keys.sort
    @is_asset     = true
    @is_error     = true
    @is_break     = true
    @is_secure    = true
    @has_articles = true
    @is_redirect  = true
    @is_grabbed   = true
    report_header

    addresses.each_index do |i|
      addr = addresses[i]

      debug = (addr == @config['debug_url'])
      @is_asset, @is_error, @is_redirect, @is_secure, parsed = examine( addr, debug)
      @is_break = false
      if @is_secure
        @is_error  =  false
        n_secure   += 1
      end

      ts   = @pages[addr]['timestamp']
      @is_grabbed = (ts != 0)
      ext  = @is_asset ? addr.split('.')[-1] : 'html'

      n_all     += 1
      n_grabbed += 1
      if @is_error
        if parsed
          n_error += 1
        else
          n_break += 1
          @is_break = true
          @is_error = false
        end
      end

      old_articles, date, tags = n_articles, '', ''
      if parsed
        parsed.tree do |child|
          if child.is_a?( Elements::Article)
            n_articles += 1
            if child.date
              date = child.date.strftime( '%Y-%m-%d')
            end

            tags = child.index.join( ' ')
          end
        end
      end

      @has_articles = (n_articles > old_articles)

      if ts == 0
        write_files "<tr><td>#{addr}</td>"
      else
        write_files "<tr><td><a target=\"_blank\" href=\"#{@cache}/#{ts}.#{ext}\">#{addr}</a></td>"
      end

      outs = []
      if refs = @pages[addr]['referrals']
        refs.each_index do |i|
          outs << "<a target=\"_blank\" href=\"#{refs[i]}\">#{i+1}</a>" if i < 3
          outs << '+' if i == 3
        end
      end
      write_files "<td>#{outs.join( '&nbsp;')}</td>"

      if parsed
        write_files "<th bgcolor=\"#{@is_error ? 'red' : 'lime'}\">"
        write_files "<a target=\"_blank\" href=\"#{i}.html\">"
        write_files( @is_error ? '&cross;' : (@is_secure ? '&timesb;' : '&check;'))
        write_files "</a></th>"
      elsif @is_redirect
        n_redirect += 1
        write_files "<th bgcolor=\"lime\">&rArr;</th>"
      elsif ts == 0
        write_files "<th bgcolor=\"yellow\">?</th>"
        n_grabbed -= 1
      elsif @is_asset
        n_asset += 1
        if @is_error || @is_break
          write_files "<th bgcolor=\"red\">&cross;</th>"
        else
          write_files "<th bgcolor=\"lime\">&check;</th>"
        end
      else
        write_files "<th bgcolor=\"red\">#{@is_secure ? '&timesb;' : '&cross;'}</th>"
      end

      write_files "<td>#{@has_articles ? (n_articles - old_articles) : ''}</td>"
      write_files "<td>#{date}</td>"
      write_files "<td>#{tags}</td>"
      write_files "<td>#{@pages[addr]['comment']}</td>"

      if ts == 0
        write_files "<td></td>"
      else
        write_files "<td>#{Time.at(ts).strftime( '%Y-%m-%d')}</td>"
      end

      if parsed
        dump( parsed, dir + "/#{i}.html", debug)
      end
      write_files "</tr>"
    end

    @is_asset     = true
    @is_error     = true
    @is_break     = true
    @is_secure    = true
    @is_redirect  = true
    @is_grabbed   = true
    @has_articles = true
    report_footer( n_all, n_articles, n_break, n_error, n_secure, n_redirect, n_asset, n_grabbed)
    close_files
  end

  def report_footer( n_all, n_articles, n_break, n_error, n_secure, n_redirect, n_asset, n_grabbed)
    stats = [
        "Pages(#{n_all})",
        "Articles(#{n_articles})",
        "Assets(#{n_asset})",
        "Breaks(#{n_break})",
        "Errors(#{n_error})",
        "Redirects(#{n_redirect})",
        "Secure(#{n_secure})",
        "Grabbed(#{n_grabbed})"
    ]

    write_files <<FOOTER1
</table></div><div class="menu"><table><tr>
FOOTER1

    stats.each_index do |i|
      stats.each_index do |j|
        if i == j
          @files[j].print "<td>#{stats[i]}</td>"
        else
          @files[j].print "<td><a href=\"index#{(i==0)?'':i}.html\">#{stats[i]}</a></td>"
        end
      end
    end

    write_files <<FOOTER2
</tr></table><div></body></html>
FOOTER2
  end

  def report_header
    write_files <<HEADER1
<html>
<head>
<style>
body {display: flex; align-items: center; flex-direction: column-reverse; justify-content: flex-end}
table {border-collapse: collapse}
.pages td, .pages th {border: 1px solid black; font-size: 20px; padding: 5px}
.menu {padding-bottom: 20px}
.menu td {font-size: 30px; padding-left: 10px; padding-right: 10px}
</style>
</head>
<body>
HEADER1

    write_files <<HEADER2
<div class="pages"><table><tr>
<th>Page</th>
<th>Refs</th>
<th>State</th>
<th>Articles</th>
<th>Date</th>
<th>Tags</th>
<th>Comment</th>
<th>Timestamp</th>
</tr>
HEADER2
  end

  def write_files( text)
    @files[0].print text
    @files[1].print text if @has_articles
    @files[2].print text if @is_asset
    @files[3].print text if @is_break
    @files[4].print text if @is_error
    @files[5].print text if @is_redirect
    @files[6].print text if @is_secure
    @files[7].print text if @is_grabbed
  end
end

a = Analyser.new( ARGV[0], ARGV[1])
a.report( ARGV[2])

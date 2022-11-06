require 'yaml'

require_relative 'processor'

class Analyser
  def initialize( config_dir, cache)
    @config    = Config.new( config_dir)
    @cache     = cache
    @processor = Processor.new( @config, cache)
  end

  def close_files
    @files.each {|io| io.close}
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
        File.open( dir + '/index7.html', 'w'),
        File.open( dir + '/index8.html', 'w')
    ]
    @is_asset = false
  end

  def report
    @report_index_counter = 0
    dir = @config.temp_dir
    @processor.subprocess 'dump'

    open_files( dir)
    n_all, n_articles, n_break, n_error, n_secure, n_redirect, n_asset, n_grabbed = 0, 0, 0, 0, 0, 0, 0, 0
    indexes = Hash.new {|h,k| h[k] = [[],[]]}

    report_header

    @processor.pages do |url|
      debug = @config.debug_url? url
      info = @processor.lookup(url)

      @is_asset    = info.asset?
      @is_break    = info.broken?
      @is_error    = info.error? && (! info.broken?) && (! info.secure?)
      @is_redirect = info.redirect?
      @is_secure   = info.secure?
      @is_grabbed  = info.timestamp > 0

      n_secure   += 1 if @is_secure
      n_all      += 1
      n_grabbed  += 1 if @is_grabbed
      n_error    += 1 if @is_error
      n_break    += 1 if @is_break
      n_asset    += 1 if @is_asset
      n_redirect += 1 if @is_redirect

      ext  = @is_asset ? url.split('.')[-1] : 'html'

      old_articles, date, tags = n_articles, '', ''
      info.articles do |article|
        n_articles += 1

        if article.date
          date = article.date
        end

        indexes[article.index.join("\t")][(article.mode == :article) ? 0 : 1] << url

        tags = article.index.join( ' / ')
      end

      @has_articles = (n_articles > old_articles)

      if File.exist?( "#{@cache}/grabbed/#{info.timestamp}.#{ext}")
        write_records "<tr><td><a target=\"_blank\" href=\"#{@cache}/grabbed/#{info.timestamp}.#{ext}\">#{url}</a></td>"
      else
        write_records "<tr><td>#{url}</td>"
      end

      outs = []
      info.referrals.each_index do |i|
        outs << "<a target=\"_blank\" href=\"#{info.referrals[i]}\">#{i+1}</a>" if i < 3
        outs << '+' if i == 3
      end
      write_records "<td>#{outs.join('&nbsp;')}</td>"

      if @is_redirect
        write_records "<th bgcolor=\"#{@is_error ? 'red' : 'lime'}\">&rArr;</th>"
      elsif (info.timestamp > 0) && (! @is_asset)
        write_records "<th bgcolor=\"#{(@is_error || @is_break) ? 'red' : 'lime'}\">"
        write_records "<a target=\"_blank\" href=\"#{info.timestamp}.html\">"
        write_records((@is_error || @is_break) ? '&cross;' : (@is_secure ? '&timesb;' : '&check;'))
        write_records "</a></th>"
      elsif info.timestamp == 0
        write_records "<th bgcolor=\"yellow\">?</th>"
      elsif @is_asset
        if @is_error || @is_break
          write_records "<th bgcolor=\"red\">&cross;</th>"
        else
          write_records "<th bgcolor=\"lime\">&check;</th>"
        end
      else
        write_records "<th bgcolor=\"red\">#{@is_secure ? '&timesb;' : '&cross;'}</th>"
      end

      write_records "<td>#{@has_articles ? (n_articles - old_articles) : ''}</td>"
      write_records "<td>#{date}</td>"
      write_records "<td>#{tags}</td>"
      write_records "<td>#{info.comment}</td>"

      if info.timestamp == 0
        write_records "<td></td>"
      else
        write_records "<td>#{Time.at(info.timestamp).strftime('%Y-%m-%d')}</td>"
      end

      write_records "</tr>"
    end

    report_indexes( indexes)
    report_footer( n_all, n_articles, n_break, n_error, n_secure, n_redirect, n_asset, n_grabbed, indexes.size)
    close_files
  end

  def report_footer( n_all, n_articles, n_break, n_error, n_secure, n_redirect, n_asset, n_grabbed, n_indexes)
    stats = [
        "Pages(#{n_all})",
        "Articles(#{n_articles})",
        "Assets(#{n_asset})",
        "Breaks(#{n_break})",
        "Errors(#{n_error})",
        "Redirects(#{n_redirect})",
        "Secure(#{n_secure})",
        "New(#{n_all-n_grabbed})",
        "Indexes(#{n_indexes})"
    ]

    write_files( 0, 8, <<FOOTER1)
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

    write_files( 0, 8, <<FOOTER2)
</tr></table><div></body></html>
FOOTER2
  end

  def report_header
    write_files( 0, 8, <<HEADER1)
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

    write_files( 0, 7, <<HEADER2)
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

    write_files( 8, 8, <<HEADER3)
<div class="pages"><table><tr>
<th>Index</th>
<th>Articles</th>
<th>Posts</th>
</tr>
HEADER3
  end

  def report_index( urls)
    return '' if urls.empty?
    @report_index_counter += 1
    File.open( @config.temp_dir + "/index_s#{@report_index_counter}.html", 'w') do |io|
      io.print <<INDEX_HEADER
<html>
<head>
<style>
body {display: flex; align-items: center;}
table {border-collapse: collapse}
td, th {border: 1px solid black; font-size: 20px; padding: 5px}
</style>
</head>
<body><table><tr><th>URL</th></tr>
INDEX_HEADER

      urls.each do |url|
        io.print <<"INDEX_LINE"
<tr><td><a target="_blank" href="#{url}">#{url}</a></td></tr>
INDEX_LINE
      end

      io.print "</table></body></html>"
    end

    "<a href=\"index_s#{@report_index_counter}.html\">#{urls.size}</a>"
  end

  def report_indexes( indexes)
    indexes.keys.sort.each do |key|
      stats = indexes[key]
      write_files( 8, 8, <<"INDEX")
<tr><td>#{key.split("\t").join(' / ')}</td><td>#{report_index(stats[0])}</td><td>#{report_index(stats[1])}</td></tr>
INDEX
    end
  end

  def write_files( from, to, text)
    (from..to).each do |i|
      @files[i].print text
    end
  end

  def write_records(text)
    @files[0].print text
    @files[1].print text if @has_articles
    @files[2].print text if @is_asset
    @files[3].print text if @is_break
    @files[4].print text if @is_error
    @files[5].print text if @is_redirect
    @files[6].print text if @is_secure
    @files[7].print text unless @is_grabbed
  end
end

a = Analyser.new( ARGV[0], ARGV[1])
a.report

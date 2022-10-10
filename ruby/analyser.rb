require 'yaml'

require_relative 'processor'

class Analyser < Processor
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
        File.open( dir + '/index7.html', 'w')
    ]
    @is_asset = false
  end

  def report
    dir = @config['temp_dir']
    subprocess 'dump'

    open_files( dir)
    n_all, n_articles, n_break, n_error, n_secure, n_redirect, n_asset, n_grabbed = 0, 0, 0, 0, 0, 0, 0, 0

    @is_asset     = true
    @is_error     = true
    @is_break     = true
    @is_secure    = true
    @has_articles = true
    @is_redirect  = true
    @is_grabbed   = false
    report_header

    pages do |url|
      debug = (url == @config['debug_url'])
      info = lookup(url)

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

        if article['date']
          date = article['date']
        end

        tags = article['index'].join( ' / ')
      end

      @has_articles = (n_articles > old_articles)

      if info.timestamp == 0
        write_files "<tr><td>#{url}</td>"
      else
        write_files "<tr><td><a target=\"_blank\" href=\"#{@cache}/#{info.timestamp}.#{ext}\">#{url}</a></td>"
      end

      outs = []
      info.referrals.each_index do |i|
        outs << "<a target=\"_blank\" href=\"#{info.referrals[i]}\">#{i+1}</a>" if i < 3
        outs << '+' if i == 3
      end
      write_files "<td>#{outs.join( '&nbsp;')}</td>"

      if @is_redirect
        n_redirect += 1
        write_files "<th bgcolor=\"#{@is_error ? 'red' : 'lime'}\">&rArr;</th>"
      elsif (info.timestamp > 0) && (! @is_asset)
        write_files "<th bgcolor=\"#{(@is_error || @is_break) ? 'red' : 'lime'}\">"
        write_files "<a target=\"_blank\" href=\"#{info.timestamp}.html\">"
        write_files( @is_error ? '&cross;' : (@is_secure ? '&timesb;' : '&check;'))
        write_files "</a></th>"
      elsif info.timestamp == 0
        write_files "<th bgcolor=\"yellow\">?</th>"
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
      write_files "<td>#{info.comment}</td>"

      if info.timestamp == 0
        write_files "<td></td>"
      else
        write_files "<td>#{Time.at(info.timestamp).strftime( '%Y-%m-%d')}</td>"
      end

      write_files "</tr>"
    end

    @is_asset     = true
    @is_error     = true
    @is_break     = true
    @is_secure    = true
    @is_redirect  = true
    @is_grabbed   = false
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
        "New(#{n_all-n_grabbed})"
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
    @files[7].print text unless @is_grabbed
  end
end

a = Analyser.new( ARGV[0], ARGV[1])
a.report

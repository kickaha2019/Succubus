require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'

require_relative 'processor'

class Reporter < Processor
  attr_reader :errors

  def initialize( site_file, cache)
    super
    @errors = 0
    find_links
  end

  def close_reports
    @files.each {|io| io.close}
  end

  def open_reports
    @files = [
        File.open( @cache + '/index.html',  'w'),    # HTML pages
        File.open( @cache + '/index1.html', 'w'),    # Assets
        File.open( @cache + '/index2.html', 'w'),    # External links
        File.open( @cache + '/index3.html', 'w'),    # Redirects
        File.open( @cache + '/index4.html', 'w'),    # Errors
        File.open( @cache + '/index5.html', 'w')     # Ungrabbed
    ]
  end

  def report
    open_reports
    report_header
    report_lines
    report_footer
    close_reports
  end

  def report_footer
    stats = [
        [0,"Pages(#{@n_all})"],
        [1,"Assets(#{@n_asset})"],
        [2,"External(#{@n_external})"],
        [3,"Redirects(#{@n_redirect})"],
        [4,"Errors(#{@n_error})"],
        [9,"Secure(#{@n_secure})"],
        [5,"New(#{@n_all-@n_grabbed})"]
    ]

    write_reports( [0,1,2,3,4,5], <<FOOTER1)
</table></div><div class="menu"><table><tr>
FOOTER1

    @files.each_index do |fi|
      stats.each do |stat|
        if (stat[0] == fi) || (stat[0] >= 9)
          @files[fi].print "<td>#{stat[1]}</td>"
        else
          @files[fi].print "<td><a href=\"index#{(stat[0] != 0) ? stat[0] : ''}.html\">#{stat[1]}</a></td>"
        end
      end
    end

    write_reports( [0,1], <<FOOTER2)
</tr></table><div></body></html>
FOOTER2
  end

  def report_header
    write_reports( [0,1,2,3,4,5], <<HEADER1)
<html>
<head>
<style>
body {display: flex; align-items: center; flex-direction: column-reverse; justify-content: flex-end}
table {border-collapse: collapse}
.pages td, .pages th {border: 1px solid black; padding: 5px}
.pages td, .pages th, span {font-size: 20px}
.menu {padding-bottom: 20px}
.menu td {font-size: 30px; padding-left: 10px; padding-right: 10px}
</style>
</head>
<body>
<div class="pages"><table><tr>
<th>Page</th>
<th>Refs</th>
<th>State</th>
<th>Comment</th>
<th>Timestamp</th>
</tr>
HEADER1
  end

  def report_lines
    @n_all, @n_asset, @n_error, @n_secure, @n_redirect, @n_grabbed = 0, 0, 0, 0, 0, 0
    @n_external = 0

    @pages.keys.sort.each do |url|
      info     = @pages[url]
      asset    = @site.asset?( url)
      redirect = info['redirect']
      error    = info['comment'] && (! redirect)
      @errors += 1 if error

      #@n_secure   += 1 if @is_secure
      @n_all      += 1
      @n_grabbed  += 1 if info['timestamp'] > 0
      @n_error    += 1 if error
      @n_asset    += 1 if asset
      @n_redirect += 1 if info['redirect']
      @n_external += 1 unless local?( url)

      files = error ? [4] : []
      if info['timestamp'] == 0
        files << 5
      elsif local?( url)
        if info['redirect']
          files << 3
        elsif asset
          files << 1
        else
          files << 0
        end
      else
        files << 2
      end

      line = []
      path = "#{@cache}/grabbed/#{info['timestamp']}.html"
      url_show = (url.size < 65) ? url : (url[0..64] + '...')
      if (! @site.asset?( url)) && File.exist?( path)
        line << "<tr><td><a target=\"_blank\" title=\"#{url}\" href=\"#{path}\">#{url_show}</a></td>"
      else
        line << "<tr><td><span title=\"#{url}\">#{url_show}</span></td>"
      end

      line << '<td>'
      refs = @refs[url]
      (0..2).each do |i|
        line << "<a href=\"#{refs[i]}\">#{i+1}</a> " if i < refs.size
      end
      line << '</td>'

      if redirect
        line << "<th bgcolor=\"#{error ? 'red' : 'lime'}\">&rArr;</th>"
      elsif (info['timestamp'] > 0) && (! asset)
        line << "<th bgcolor=\"#{error ? 'red' : 'lime'}\">"
        line << "<a target=\"_blank\" href=\"#{path}\">"
        line <<( error ? '&cross;' : '&check;')
        line << "</a>"
        line << "</th>"
      elsif info['timestamp'] == 0
        line << "<th bgcolor=\"yellow\">?</th>"
      elsif asset
        if error
          line << "<th bgcolor=\"red\">&cross;</th>"
        else
          line << "<th bgcolor=\"lime\">&check;</th>"
        end
      else
        line << "<th bgcolor=\"red\">&cross;</th>"
      end

      line << "<td>#{info['comment']}</td>"

      if info['timestamp'] == 0
        line << "<td></td>"
      else
        line << "<td>#{Time.at(info['timestamp']).strftime('%Y-%m-%d')}</td>"
      end

      line << "</tr>"

      write_reports( files, line.join( "\n"))
    end
  end

  def write_reports( files, text)
    (files).each do |i|
      @files[i].print text
    end
  end
end

g = Reporter.new( ARGV[0], ARGV[1])
g.report
exit 1 if g.errors > 0

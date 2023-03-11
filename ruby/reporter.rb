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
  end

  def close_reports
    @files.each {|io| io.close}
  end

  def open_reports
    @files = [
        File.open( @cache + '/index.html',  'w'),
        File.open( @cache + '/index1.html', 'w')
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
        [1,"Errors(#{@n_error})"],
        [9,"Redirects(#{@n_redirect})"],
        [9,"Secure(#{@n_secure})"],
        [9,"New(#{@n_all-@n_grabbed})"]
    ]

    write_reports( [0,1], <<FOOTER1)
</table></div><div class="menu"><table><tr>
FOOTER1

    @files.each_index do |fi|
      stats.each do |stat|
        if stat[0] == fi
          @files[fi].print "<td>#{stat[1]}</td>"
        else
          @files[fi].print "<td><a href=\"index#{stat[0]}.html\">#{stat[1]}</a></td>"
        end
      end
    end

    write_reports( [0,1], <<FOOTER2)
</tr></table><div></body></html>
FOOTER2
  end

  def report_header
    write_reports( [0,1], <<HEADER1)
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
<div class="pages"><table><tr>
<th>Page</th>
<th>State</th>
<th>Comment</th>
<th>Timestamp</th>
</tr>
HEADER1
  end

  def report_lines
    @n_all, @n_asset, @n_error, @n_secure, @n_redirect, @n_grabbed = 0, 0, 0, 0, 0, 0
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

      line = []
      ext  = @site.asset?( url) ? url.split('.')[-1] : 'html'
      path = "#{@cache}/grabbed/#{info['timestamp']}.#{ext}"
      if File.exist?( path)
        line << "<tr><td><a target=\"_blank\" href=\"#{path}\">#{url}</a></td>"
      else
        line << "<tr><td>#{url}</td>"
      end

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

      write_reports( [0] + (error ? [1] : []), line.join( "\n"))
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

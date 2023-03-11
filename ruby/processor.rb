require 'nokogiri'
require 'yaml'
require 'pry'

require_relative 'config'

class Processor
  attr_reader :pages

  def initialize( site_file, cache)
    require site_file
    @site_file = site_file
    site_class = site_file.split('/')[-1].split('.')[0].capitalize
    @site      = Kernel.const_get( site_class).new
    @cache     = cache

    @pages = {}
    if File.exist?( cache + '/grabbed.yaml')
      @pages = YAML.load( IO.read( cache + '/grabbed.yaml'))
      timestamps = {}
      errors     = false
      @pages.each_pair do |url, info|
        if (ts = info['timestamp']) > 0
          if timestamps[ts]
            puts "*** Same timestamp: #{url} and #{timestamps[ts]}"
          else
            timestamps[ts] = url
          end
        end
      end
      raise "Duplicate timestamps" if errors
    end
  end

  def find_links
    subprocess 'find_links'
    @links = Hash.new {|h,k| h[k] = []}

    Dir.entries( @cache).each do |f|
      if /\.txt/ =~ f
        IO.readlines( @cache + '/' + f).each do |line|
          if m = /^(.*)\t(.*)$/.match( line)
            @links[m[1]] << m[2]
          end
        end
      end
    end
  end

  def in_site( url)
    @site.root_url == url[0...(@site.root_url.size)]
  end

  def local?( url)
    return true unless /^\w*:/ =~ url
    root_url = @site.root_url
    return false unless url.size > root_url.size
    url[0...root_url.size] == root_url
  end

  def parse( path)
    Nokogiri::HTML( IO.read( path))
  end

  def subprocess( verb)
    pids = []
    loop = 10
    (0...loop).each do |i|
      pids << spawn( "/Users/peter/Succubus/bin/worker.command #{@site_file} #{@cache} #{verb} #{i} #{loop}")
    end

    error = false
    pids.each do |pid|
      Process.wait pid
      error = true unless $?.exitstatus == 0
    end

    raise "Subprocess error" if error
  end
end

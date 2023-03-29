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

  def absolutise( page_url, url)
    return nil if url.nil?
    url = url.strip.sub( /#.*$/, '')
    url = url[2..-1] if /^\.\// =~ url
    return nil if url == ''

    url = url.strip.gsub( '%20', ' ').gsub( '\\', '/')
    url = url.gsub( /.\/\//) do |match|
      (match == '://' ? match : match[0..1])
    end

    root_url = @site.root_url
    dir_url  = page_url.split('?')[0]

    if /^\?/ =~ url
      return dir_url + url
    end

    if /\/$/ =~ dir_url
      dir_url = dir_url[0..-2]
    else
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    while /^\.\.\// =~ url
      url     = url[3..-1]
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    if /^\// =~ url
      url = root_url + url[1..-1]
    elsif /^\w*:/ =~ url
    else
      url = dir_url + '/' + url
    end

    old_url = ''
    while old_url != url
      old_url = url
      url = url.sub( /\/[a-z0-9_\-]+\/\.\.\//i, '/')
    end

    url1 = url.sub( /^http:/, 'https:')
    if local?(url1)
      url = @site.respond_to?( :simplify_url) ? @site.simplify_url( url1) : url1
    end

    url
  end

  def find_classes
    subprocess 'find_classes'
    load_classes
  end

  def find_links
    subprocess 'find_links'
    load_links
  end

  def in_site( url)
    @site.root_url == url[0...(@site.root_url.size)]
  end

  def load_classes
    @classes = Hash.new {|h,k| h[k] = []}

    Dir.entries( @cache).each do |f|
      if /classes\d*\.txt/ =~ f
        IO.readlines( @cache + '/' + f).each do |line|
          if m = /^(.*)\t(.*)$/.match( line)
            @classes[m[1]] << m[2]
          end
        end
      end
    end

    @classes.keys.each do |key|
      @classes[key] = @classes[key].uniq
    end

    @class_used = Hash.new {|h,k| h[k] = []}
    @classes.each_pair do |page, links|
      links.each {|link| @class_used[link] << page}
    end
  end

  def load_links
    @links = Hash.new {|h,k| h[k] = []}

    Dir.entries( @cache).each do |f|
      if /links\d*\.txt/ =~ f
        IO.readlines( @cache + '/' + f).each do |line|
          if m = /^(.*)\t(.*)$/.match( line)
            @links[m[1]] << m[2]
          end
        end
      end
    end

    @links.keys.each do |key|
      @links[key] = @links[key].uniq
    end

    @refs = Hash.new {|h,k| h[k] = []}
    @links.each_pair do |page, links|
      links.each {|link| @refs[link] << page}
    end
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

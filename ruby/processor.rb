require 'nokogiri'
require 'yaml'
require 'pry'

require_relative 'config'

class Processor
  attr_reader :pages

  def initialize( config, cache)
    @config = config # YAML.load( IO.read( config + '/config.yaml'))
    @cache = cache

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

  def asset?( url)
    ! html?( url)
  end

  def html?( url)
    /\/[^\.\/]*(|\.htm|\.html)$/ =~ url
  end

  def local?( url)
    return true unless /^\w*:/ =~ url
    root_url = @config.root_url
    return false unless url.size > root_url.size
    url[0...root_url.size] == root_url
  end

  def parse( path)
    Nokogiri::HTML( IO.read( path))
  end

  def subprocess( verb)
    pids = []
    loop = @config.n_workers
    (0...loop).each do |i|
      pids << spawn( "/Users/peter/Succubus/bin/worker.command #{verb} #{i} #{loop}")
    end

    error = false
    pids.each do |pid|
      Process.wait pid
      error = true unless $?.exitstatus == 0
    end

    raise "Subprocess error" if error
  end
end

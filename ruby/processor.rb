require 'yaml'
require_relative 'site'

class Processor
  def initialize( config, cache)
    @config     = YAML.load( IO.read( config + '/config.yaml'))
    @config_dir = config

    Dir.entries( config).each do |f|
      if /\.rb$/ =~ f
        require( config + '/' + f)
      end
    end

    @cache = cache
    @site  = Kernel.const_get( @config['class']).new( @config)

    if File.exist?( cache + '/grabbed.yaml')
      @pages = YAML.load( IO.read( cache + '/grabbed.yaml'))
    else
      @pages = {}
    end

    @exclude_url_strings = []
    @exclude_url_regexes = []

    if @config['exclude_urls']
      @config['exclude_urls'].each do |url|
        if /^\^/ =~ url
          @exclude_url_regexes << Regexp.new( url)
        else
          @exclude_url_strings << url
        end
      end
    end
  end

  def asset?( url)
    @site.asset?( url)
  end

  def exclude_url?( url)
    return true if @exclude_url_strings.include?( url)
    @exclude_url_regexes.each do |re|
      return true if re =~ url
    end
    false
  end

  def preparse_all
    @pages.each_pair do |url, info|
      if ts = info['timestamp']
        path = "#{@cache}/#{ts}.html"
        if File.exist?( path)
          @site.preparse( url, IO.read( path))
        end
      end
    end
  end

  def parse( url, ts)
    body = IO.read( "#{@cache}/#{ts}.html")
    @site.parse( url, body)
  end
end

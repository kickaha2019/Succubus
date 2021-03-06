require 'yaml'
require 'pry'

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
        if /[\\^$]/ =~ url
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

  def examine( url)
    info = @pages[url]
    ts   = info['timestamp']

    if ts == 0
      return asset?(url),
             (info['comment'] && (! info['redirect'])),
             info['redirect'],
             info['secured']
             nil
    end

    if info['redirect']
      return asset?( url), false, true, info['secured'], nil
    end

    if asset?( url)
      return asset?( url), info['comment'], false, info['secured'], nil
    end

    unless File.exist?( @cache + "/#{ts}.html")
      # p ['examine1', url]
      return false, true, false, info['secured'], nil
    end

    begin
      parsed = parse( url, ts)

      error = parsed.content?
      parsed.tree do |child|
        child_error, _ = child.error?
        error = true if child_error
      end

      return false, error, false, info['secured'], parsed
    rescue
      puts "*** File: #{info['timestamp']}.html"
      raise
    end
  end

  def parse( url, ts)
    body = IO.read( "#{@cache}/#{ts}.html")
    @site.parse( url, body)
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

  def propagate_redirects
    @pages.each_key do |url|
      target = url
      while @pages[target] && @pages[target]['redirect']
        target = @pages[target]['comment']
      end
      if url != target
        @site.redirect( url, target)
      end
    end
  end
end

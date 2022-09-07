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

  def examine( url, debug = false)
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

    if info['parsed']
      return false, info['error'], false, info['secured'], info['parsed']
    end

    unless File.exist?( @cache + "/#{ts}.html")
      puts "examine1: #{url}" if debug
      return false, true, false, info['secured'], nil
    end

    begin
      info['parsed'] = parse( url, info)

      error = info['parsed'].content?
      info['parsed'].tree do |child|
        child_error, child_msg = child.error?
        if child_error
          p ['examine3', child.index, child.class.to_s, child_msg] if debug
          error = true
        end
      end

      info['error'] = error
      return false, error, false, info['secured'], info['parsed']
    rescue
      puts "*** File: #{info['timestamp']}.html"
      raise
    end
  end

  def parse( url, info)
    unless info['document']
      info['document'] = @site.parse_document( "#{@cache}/#{ts}.html")
    end
    @site.parse( url, info['document'])
  end

  def preparse_all
    @pages.each_pair do |url, info|
      if ts = info['timestamp']
        path = "#{@cache}/#{ts}.html"
        if File.exist?( path)
          info['document'] = @site.parse_document( path)
          @site.preparse( url, info['document'])
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

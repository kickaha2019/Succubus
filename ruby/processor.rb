require 'yaml'
require 'pry'

require_relative 'site'

class Processor
  class ArticleInfo
    attr_reader :url, :order

    def initialize( url, order, info)
      @url   = url
      @order = order
      @info  = info
    end

    def date
      @info['date']
    end

    def index
      @info['index']
    end

    def mode
      @info['mode'].to_sym
    end

    def root?
      mode == :home
    end

    def title
      @info['title']
    end
  end

  class PageInfo
    def initialize( processor, cache, url, info, digest)
      @processor = processor
      @cache     = cache
      @url       = url
      @info      = info
      @digest    = digest
      @digests   = nil
    end

    def articles
      if @digest
        @digest['articles'].each_index do |i|
          yield( ArticleInfo.new( @url, i, @digest['articles'][i]))
        end
      end
    end

    def asset?
      @processor.asset?( @url)
    end

    def broken?
      return false if secure? || redirect?
      error? && @digest.nil?
    end

    def comment
      @info['comment']
    end

    def error?
      if @digest
        @digest['error']
      else
        return @processor.deref_error(@url) if redirect?
        comment
      end
    end

    def links
      if @digest
        @digest['links'].each do |link|
          yield link
        end
      end
    end

    def redirect?
      @info['redirect']
    end

    def referrals
      @info['referrals']
    end

    def secure?
      @info['secured']
    end

    def timestamp
      @info['timestamp']
    end
  end

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

    @pages = {}
    if File.exist?( cache + '/grabbed.yaml')
      @pages = YAML.load( IO.read( cache + '/grabbed.yaml'))
      timestamps = {}
      errors     = false
      @pages.each_pair do |url, info|
        if (ts = info['timestamp']) > 0
          if timestamps[ts]
            errors = true
            puts "*** Same timestamp: #{url} and #{timestamps[ts]}"
          else
            timestamps[ts] = url
          end
        end
      end
      raise "Duplicate timestamps" if errors
    end

    @page_data = Hash.new {|h,k| h[k] = {}}

    unless File.exist?( @config['temp_dir'])
      Dir.mkdir( @config['temp_dir'])
    end
  end

  def asset?( url)
    @site.asset?( url)
  end

  def deref( url)
    url, _ = deref_with_limit( url)
    url
  end

  def deref_error(url)
    url, limit = deref_with_limit( url)
    (limit == 0) # || @pages[url].nil?
  end

  def deref_with_limit( url)
    limit = 3
    while limit > 0
      if info = @pages[url]
        if info['redirect']
          url   =  info['comment']
          limit -= 1
        else
          break
        end
      else
        break
      end
    end
    return url, limit
  end

  def lookup( url)
    return nil unless @pages[url]

    unless @digests
      @digests = {}
      digested = []
      (0...@config['workers']).each do |i|
        digested << YAML.load( IO.read( @config['temp_dir'] + "/digest#{i}.yaml"))
      end

      digested.each do |digest|
        digest.each_pair do |url, info|
          @digests[url] = info unless /^advise:/ =~ url
        end
      end

      digested.each do |digest|
        digest.each_pair do |url, advice|
          next unless /^advise:/ =~ url
          if info = @digests[deref(url[7..-1])]
            if info['articles'].size == 1
              article = info['articles'][0]
              article['index'] = advice['index'] if advice['index'] && article['index'].empty?
              article['title'] = advice['title'] if advice['title']
              article['date']  = advice['date']
              article['mode']  = advice['mode']
            end
          end
        end
      end
      #puts "... Consumed    #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
    end

    PageInfo.new( self, @cache, url, @pages[url], @digests[url])
  end

  def pages
    @pages.keys.sort.each {|url| yield url}
  end

  def parse( url, info)
    unless @page_data[url]['document']
      @page_data[url]['document'] = @site.parse_document( "#{@cache}/grabbed/#{info['timestamp']}.html")
    end
    @site.parse( url, @page_data[url]['document'])
  end

  def propagate_redirects
    @pages.each_key do |url|
      target = deref(url)
      if url != target
        @site.redirect( url, target)
      end
    end
  end

  def subprocess( verb)
    pids = []
    loop = @config['workers']
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

  # def unify( url)
  #   return url if @pages[url]
  #   if /\/$/ =~ url
  #     return url[0..-2] if @pages[url[0..-2]]
  #   else
  #     return( url + '/') if @pages[url + '/']
  #   end
  #   url
  # end
end

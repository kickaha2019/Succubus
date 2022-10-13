require 'yaml'
require 'pry'

require_relative 'site'

class Processor
  class ArticleInfo
    def initialize( info)
      @info      = info
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
        @digest['articles'].each do |article|
          yield( ArticleInfo.new(article))
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
          url   =  unify(info['comment'])
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

  def examine( url, debug = false)
    info = @pages[url]
    unless info
      return false, true, false, false, nil
    end
    ts   = info['timestamp']

    if ts == 0
      return asset?(url),
             (info['comment'] && (! info['redirect'])),
             info['redirect'],
             info['secured']
             nil
    end

    if info['redirect']
      return asset?( url), deref_error(url), true, info['secured'], nil
    end

    if asset?( url)
      return asset?( url), info['comment'], false, info['secured'], nil
    end

    if @page_data[url]['parsed']
      return false, @page_data[url]['error'], false, info['secured'], @page_data[url]['parsed']
    end

    unless File.exist?( @cache + "/grabbed/#{ts}.html")
      puts "examine1: #{url}" if debug
      return false, true, false, info['secured'], nil
    end

    begin
      parsed = @page_data[url]['parsed'] = parse( url, info)

      error = parsed.content?
      parsed.tree do |child|
        child_error, child_msg = child.error?
        if child_error
          p ['examine3', child.index, child.class.to_s, child_msg] if debug
          error = true
        end
      end

      @page_data[url]['error'] = error
      return false, error, false, info['secured'], parsed
    rescue
      puts "*** File: #{info['timestamp']}.html"
      raise
    end
  end

  def lookup( url)
    return nil unless @pages[url]
    unless @digests
      @digests = {}
      (0...@config['workers']).each do |i|
        YAML.load( IO.read( @config['temp_dir'] + "/digest#{i}.yaml")).each_pair do |url, info|
          @digests[url] = info
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

#  def preparse_all
#    suppress_indexes = []

    # @pages.each_pair do |url, info|
    #   if ts = info['timestamp']
    #     path = "#{@cache}/grabbed/#{ts}.html"
    #     if File.exist?( path)
    #       @page_data[url]['document'] = @site.parse_document( path)
    #       @site.preparse( url, @page_data[url]['document'])
    #     end
    #   end
    # end

    #   _, _, _, _, parsed = examine( deref( url))  # Parsing may not have been yet
    #
    #   if parsed
    #     parsed.tree do |child|
    #       if child.is_a?( Elements::Article)
    #         if /bgj\/01901/ =~ url
    #           p ['preparse_all2', url, info['referrals']]
    #         end
    #         suppress_child_article_indexing( url, info['referrals'], child, suppress_indexes)
    #       end
    #     end
    #   end
    # end
    #
    # suppress_indexes.each {|article| article.index = []}
#  end

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

  # def suppress_child_article_indexing( url, referrals, child, suppress_indexes)
  #   return if child.index.empty?
  #
  #   referrals.each do |referral|
  #     unless @pages[unify( referral)]
  #       p ['suppress_child_article_indexing', url, referral, unify(referral)]
  #     end
  #     _, _, _, _, parsed = examine( unify( referral))
  #     if parsed
  #       parsed.tree do |parent|
  #         if parent.is_a?( Elements::Article)
  #           suppress = true
  #           child.index.each_index do |i|
  #             suppress = false unless child.index[i] == parent.index[i]
  #           end
  #
  #           if suppress
  #             suppress_indexes << child
  #             return
  #           end
  #         end
  #       end
  #     end
  #   end
  # end

  def unify( url)
    return url if @pages[url]
    if /\/$/ =~ url
      return url[0..-2] if @pages[url[0..-2]]
    else
      return( url + '/') if @pages[url + '/']
    end
    url
  end
end

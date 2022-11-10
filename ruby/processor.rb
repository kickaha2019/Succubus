require 'yaml'
require 'pry'

require_relative 'config'

class Processor
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
      @digest ? @digest['articles'] : 0
    end

    def articles?
      articles > 0
    end

    def asset?
      @processor.asset?( @url)
    end

    def broken?
      return false if secure? || redirect?
      error? && @digest.nil?
    end

    def changed
      @info['changed'] ? @info['changed'] : 0
    end

    def comment
      @info['comment']
    end

    def date
      @digest ? @digest['date'] : nil
    end

    def error?
      if @digest
        @digest['error']
      else
        return @processor.deref_error(@url) if redirect?
        comment
      end
    end

    def index
      @digest ? @digest['index'] : nil
    end

    def indexed?
      index && (! index.empty?)
    end

    def links
      if @digest
        @digest['links'].each do |link|
          yield link
        end
      end
    end

    def mode
      @digest ? @digest['mode'].to_sym : nil
    end

    def redirect?
      @info['redirect']
    end

    def referrals
      @info['referrals']
    end

    def root?
      mode == :home
    end

    def secure?
      @info['secured']
    end

    def timestamp
      @info['timestamp']
    end

    def title
      @digest ? @digest['title'] : nil
    end
  end

  def initialize( config, cache)
    @config = config # YAML.load( IO.read( config + '/config.yaml'))

    # Dir.entries( config).each do |f|
    #   if /\.rb$/ =~ f
    #     require( config + '/' + f)
    #   end
    # end

    @cache = cache
    @site  = @config.site # Kernel.const_get( @config['class']).new( @config)

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

    unless File.exist?( @config.temp_dir)
      Dir.mkdir( @config.temp_dir)
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

  def index_alfa_ranges
    alfa_sections = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = []}}

    @digests.each_value do |info|
      if info['index'][1] == '*'
        letter = (/^[a-z]/i =~ info['title']) ? info['title'][0..0].upcase : '#'
        alfa_sections[info['index'][0]][letter] << info
      end
    end

    alfa_sections.each_pair do |section, groups|
#      p ['index_alfa_ranges1', section, groups.keys, groups.values.inject(0) {|r,v| r + v.size}]
      from  = 'A'
      infos = groups.key?( 'A') ? groups.delete('A') : []

      letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      (1...(letters.size)).each do |i|
        key = letters[i..i]
        infos1 = groups.key?( key) ? groups.delete(key) : []
        if (! infos1.empty?) && ((infos.size + infos1.size) > 20)
          last = letters[(i-1)..(i-1)]
          groups[ (from == last) ? from : "#{from}-#{last}"] = infos
          from, infos = key, infos1
        else
          infos += infos1
        end
      end

      groups[ (from =='Z') ? from : "#{from}-Z"] = infos
#      p ['index_alfa_ranges2', section, groups.keys, groups.values.inject(0) {|r,v| r + v.size}]

      groups.each_pair do |range,pages|
        pages.each do |page|
          page['index'] = [section, range]
        end
      end
    end
  end

  def lookup( url)
    return nil unless @pages[url]

    unless @digests
      @digests = {}
      digested = []
      (0...@config.n_workers).each do |i|
        digested << YAML.load( IO.read( @config.temp_dir + "/digest#{i}.yaml"))
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
            info['index'] = advice['index'] if advice['index'] && info['index'].empty?
            info['title'] = advice['title'] if advice['title']
            info['date']  = advice['date']
            info['mode']  = advice['mode']
          end
        end
      end

      index_alfa_ranges
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

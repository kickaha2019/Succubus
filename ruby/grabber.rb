require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'

require_relative 'processor'

class Grabber < Processor
  def initialize( config, cache)
    super
    @root      = @config['root_url']
    @traced    = {}
    @reachable = {}
  end

  def check_files_deleted
    @pages.each_pair do |url, page|
      next if page['redirect']
      next if page['secured']

      #p ['check_files_deleted', url, asset?( url)]
      ext = 'html'
      if asset?( url)
        ext = url.split('.')[-1]
      end
      unless File.exist?( @cache + "/#{page['timestamp']}.#{ext}")
        page['timestamp'] = 0
      end
    end
  end

  def clean_cache
    @pages, old_pages = {}, @pages
    old_pages.each_pair do |url, info|
      @pages[url] = info if @reachable[url]
    end

    extant = {}
    @pages.each_value {|page| extant[page['timestamp'].to_i] = true}

    to_delete = []
    Dir.entries( @cache).each do |f|
      if m = /^(\d+)\.\w*$/.match( f)
        to_delete << f unless extant[ m[1].to_i]
      end
    end

    to_delete.each do |f|
      File.delete( "#{@cache}/#{f}")
    end
  end

  def elide_unreachable
    @pages, old_pages = {}, @pages
    old_pages.each_pair do |url, info|
      @pages[url] = info if @reachable[url]
    end
  end

  def get_candidates( limit, explicit)
    if explicit
      @candidates = [explicit]
      return
    end
    @candidates = []

    @pages.each_pair do |url, info|
      if asset? url
        if info['timestamp'] == 0
          @candidates << url
        end
      else
        @candidates << url unless info['secured']
      end
    end

    @candidates = @candidates.sort_by {|url| @pages[url]['timestamp']}[0...limit]
  end

  def grab_candidates
    @candidates.each do |url|
      puts "... Grabbing #{url}"
      ts = Time.now.to_i
      referer = @pages[url]['referral']
      info    = @pages[url] = {'timestamp' => ts,
                            'referral'     => referer}

      begin
        URI.parse( url)
      rescue URI::InvalidURIError => bang
        info['comment'] = "#{bang.message}"
        next
      end

      response = http_get( url, 30, 'Referer' => referer)
      if response.is_a?( Net::HTTPOK)
        ext = 'html'
        if asset?( url)
          ext = url.split('.')[-1]
        end
        File.open( "#{@cache}/#{ts}.#{ext}", 'wb') do |io|
          io.write response.body
        end

      elsif response.is_a?( Net::HTTPRedirection)
        url = response['Location']
        if login_redirect?( url)
          info['secured'] = true
        else
          info['comment']  = url
          info['redirect'] = true
        end

      else
        info['comment'] = "#{response.class.name}: #{response.code}"
      end
    end
  end

  def http_get( url, delay = 30, headers = {})
    sleep delay
    uri = URI.parse( url)

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Accept']          = 'text/html,application/xhtml+xml,application/xml'
    request['Accept-Language'] = 'en-gb'
    request['User-Agent']      = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'

    headers.each_pair do |k,v|
      request[k] = v
    end

    use_ssl     = uri.scheme == 'https'
    verify_mode = OpenSSL::SSL::VERIFY_NONE

    Net::HTTP.start( uri.hostname, uri.port, :use_ssl => use_ssl, :verify_mode => verify_mode) {|http|
      http.request( request)
    }
  end

  def initialise_reachable
    reached( nil, @root)
    if @config['include_urls']
      @config['include_urls'].each do |url|
        reached( nil, url)
      end
    end
  end

  def login_redirect?( url)
    lru = @config['login_redirect_url']
    return false if lru.nil?
    (lru + '?') == url[0..(lru.size)]
  end

  def reached( referral, url)
    @reachable[url] = true
    if @pages[url]
      @pages[url]['referral'] = referral
    else
      @pages[url] = {'timestamp' => 0, 'referral' => referral}
    end
  end

  def save_info
    File.open( "#{@cache}/grabbed.yaml", 'w') do |io|
      io.print @pages.to_yaml
    end
  end

  def to_trace
    @pages.each_pair do |url, info|
      next if @traced[url]
      return url if @reachable[url]
    end
    nil
  end

  def trace?( url)
    return false unless @root == url[0...(@root.size)]
    ! exclude_url?( url)
  end

  def trace_from_reachable
    while url = to_trace
      #p ['trace_from_reachable1', url, @pages[url]['timestamp']]
      @traced[url] = true
      next if @pages[url]['timestamp'] == 0
      #p ['trace_from_reachable2', url, asset?( url)]
      next if asset?( url)

      if @pages[url]['redirect']
        reached( url, @pages[url]['comment'])
        next
      end
      next if @pages[url]['comment']

      path = @cache + "/#{@pages[url]['timestamp']}.html"
      if File.exist?( path)
        parsed = parse( url, @pages[url])
        parsed.links do |found|
          found = found.split( '#')[0]
          if trace?( found)
            reached( url, found)
          end
        end
      else
        @pages[url]['timestamp'] = 0
      end
    end

    # p @reachable
    # raise 'Dev'
  end
end

g = Grabber.new( ARGV[0], ARGV[1])
g.check_files_deleted
g.initialise_reachable
g.trace_from_reachable
g.elide_unreachable
g.get_candidates( ARGV[2].to_i, ARGV[3])
g.grab_candidates
g.clean_cache
g.save_info

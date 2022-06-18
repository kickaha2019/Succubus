require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'

require_relative 'parser'

class Grabber
  def initialize( config, cache)
    @config = YAML.load( IO.read( config + '/config.yaml'))
    @root   = @config['root_url']
    @cache  = cache
    @pages  = {}
    @parser = Parser.new( config)

    if File.exist?( cache + '/grabbed.yaml')
      @pages = YAML.load( IO.read( cache + '/grabbed.yaml'))
    end
  end

  def clean_cache
    extant = {}
    @pages.each_value {|page| extant[page['timestamp'].to_i] = true}

    to_delete = []
    Dir.entries( @cache).each do |f|
      if m = /^(.*)\.(html|png|gif|jpg|jpeg)$/.match( f)
        to_delete << f unless extant[ m[1].to_i]
      end
    end

    to_delete.each do |f|
      File.delete( "#{@cache}/#{f}")
    end
  end

  def get_candidates( limit, explicit)
    if explicit
      @candidates = [explicit]
      return
    end
    @candidates = []

    @traced.each_pair do |url, info|
      if @parser.asset_url info['url']
        if info['timestamp'] == 0
          @candidates << url
        end
      else
        @candidates << url
      end
    end

    @candidates = @candidates.sort_by {|url| @traced[url]['timestamp']}[0...limit]
  end

  def grab_candidates
    @candidates.each do |url|
      puts "... Grabbing #{url}"
      ts = Time.now.to_i

      begin
        redirect, body_or_url = http_get( url)
        if redirect
          if login_redirect?( body_or_url)
            @traced[url] = {'timestamp' => ts, 'secured' => true}
          else
            @traced[url] = {'timestamp' => ts, 'comment' => body_or_url, 'redirect' => true}
          end
        else
          File.open( "#{@cache}/#{ts}.html", 'wb') do |io|
            io.write body_or_url
          end
          @traced[url] = {'timestamp' => ts}
        end
      rescue Exception => bang
        @traced[url] = {'timestamp' => 0, 'comment' => bang.message}
      end
    end

    @pages = @traced
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

    response = Net::HTTP.start( uri.hostname, uri.port, :use_ssl => use_ssl, :verify_mode => verify_mode) {|http|
      http.request( request)
    }

    if response.is_a?( Net::HTTPRedirection)
      return true, response['Location']
    end

    response.value
    return false, response.body
  end

  def login_redirect?( url)
    lru = @config['login_redirect_url']
    return false if lru.nil?
    (lru + '?') == url[0..(lru.size)]
  end

  def save_info
    File.open( "#{@cache}/grabbed.yaml", 'w') do |io|
      io.print @pages.to_yaml
    end
  end

  def trace( url)
    if trace?( url)
      if @pages[url]['redirect']
        found = @pages[url]['comment']
        if @pages[found]
          trace( found)
        else
          @traced[found] = {'timestamp' => 0}
        end
      elsif @pages[url]['comment'].nil?
        path = @cache + "/#{@pages[url]['timestamp']}.html"
        if File.exist?( path)
          parsed = @parser.parse( url, IO.read( path))
          parsed.links do |found|
            found = found.split( /[#\?]/)[0]
            p found
            if trace_doc?( found)
              if @pages[found]
                @traced[found] = @pages[found]
              else
                @traced[found] = {'timestamp' => 0}
              end
            end
          end
        end
      end
    end
  end

  def trace_doc?( url)
    return false unless @root == url[0...(@root.size)]
    ! ( @config['exclude_urls'] && @config['exclude_urls'].include?( url))
  end

  def trace_from_roots
    @traced = {@root => (@pages[@root] ? @pages[@root] : {'timestamp' => 0})}
    if @config['include_urls']
      @config['include_urls'].each do |url|
        @traced[url] = @pages[url] ? @pages[url] : {'timestamp' => 0}
      end
    end
    trace( @root)
    if @config['include_urls']
      @config['include_urls'].each do |url|
        trace url
      end
    end
  end

  def trace?( url)
    @pages[url] && @pages[url].has_key?( 'timestamp') && (url != @config['login_redirect_url'])
  end
end

g = Grabber.new( ARGV[0], ARGV[1])
g.trace_from_roots
g.get_candidates( ARGV[2].to_i, ARGV[3])
g.grab_candidates
g.clean_cache
g.save_info

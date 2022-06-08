require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'

class Grabber
  def initialize( config, cache)
    @config = YAML.load( IO.read( config + '/config.yaml'))
    @root   = @config['root_url']
    @cache  = cache
    @pages  = {}

    if File.exist?( cache + '/grabbed.yaml')
      @pages = YAML.load( IO.read( cache + '/grabbed.yaml'))
    end
  end

  def clean_cache
    extant = {}
    @pages.each_value {|page| extant[page['timestamp'].to_i] = true}

    to_delete = []
    Dir.entries( @cache).each do |f|
      if m = /^(.*)\.html$/.match( f)
        to_delete << m[1] unless extant[ m[1].to_i]
      end
    end

    to_delete.each do |ts|
      File.delete( "#{@cache}/#{ts}.html")
    end
  end

  def get_candidates( limit)
    @candidates = @traced.keys.sort_by {|url| @traced[url]['timestamp']}[0...limit]
  end

  def grab_candidates
    @candidates.each do |url|
      ts = Time.now.to_i
      begin
        redirect, body = http_get( url)
        if redirect
          if login_redirect?( body)
            @traced[url] = {'timestamp' => ts, 'secured' => true}
          else
            @traced[url] = {'timestamp' => ts, 'comment' => body}
          end
        else
          File.open( "#{@cache}/#{ts}.html", 'w') do |io|
            io.print body
          end
          @traced[url] = {'timestamp' => ts}
        end
      rescue Exception => bang
        @traced[url] = {'timestamp' => ts, 'comment' => bang.message}
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
      body = IO.read( @cache + "/#{@pages[url]['timestamp']}.html")
      body.scan( /<\s*a\s+[^>]*>/).each do |link|
        if m = /href\s*=\s*"([^"]*)"/.match( link)
          found = m[1].gsub( /#.*$/, '')
          found = @root + found[1..-1] if /^\/./ =~ found
          if @root == found[0...(@root.size)]
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

  def trace_from_root
    @traced = {@root => (@pages[@root] ? @pages[@root] : {'timestamp' => 0})}
    trace( @root)
  end

  def trace?( url)
    @pages[url] && @pages[url].has_key?( 'timestamp') && (url != @config['login_redirect_url'])
  end
end

g = Grabber.new( ARGV[0], ARGV[1])
g.trace_from_root
g.get_candidates( ARGV[2].to_i)
g.grab_candidates
g.clean_cache
g.save_info

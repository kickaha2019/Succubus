require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'

require_relative 'processor'

class Grabber < Processor
  def initialize( site_file, cache)
    super
    @root      = @site.root_url
    #@traced    = {}
    @to_trace  = []
    @reachable = {}
    @delay     = 0
  end

  def check_files_deleted
    @reachable.each_pair do |url, page|
      next if page['secured']
      next if page['comment']

      ext = 'html'
      if @site.asset?( url)
        ext = url.split('.')[-1]
      end
      unless File.exist?( @cache + "/grabbed/#{page['timestamp']}.#{ext}")
        page['timestamp'] = 0
      end
    end
  end

  def clean_cache
    extant = {}
    @pages.each_value {|page| extant[page['timestamp'].to_i] = true}
    clean_cache1( @cache) {|f| /\.txt$/ =~ f}
    clean_cache1( @cache + '/grabbed') do |f|
      if m = /^(\d+)\.\w*$/.match( f)
        ! extant[ m[1].to_i]
      else
        false
      end
    end
  end

  def clean_cache1( dir)
    to_delete = []
    Dir.entries( dir).each do |f|
      to_delete << f if yield f
    end

    to_delete.each do |f|
      File.delete( "#{dir}/#{f}")
    end
  end

  def get_candidates( limit, explicit)
    if explicit
      @candidates = [explicit]
      return
    end

    must, recent, poss = [], [], []
    months3 = Time.now.to_i - 90 * 24 * 60 * 60

    @reachable.each_pair do |url, info|
      if @site.asset? url
        if info['timestamp'] == 0
          must << url
        else
          poss << url
        end
      elsif info['timestamp'] == 0
        must << url
      elsif info['changed'] > months3
        recent << url
      else
        poss << url
      end
    end

    @candidates = (must +
                   recent.sort_by {|url| @reachable[url]['timestamp']} +
                   poss.sort_by {|url| @reachable[url]['timestamp']})[0...limit]
  end

  def grab_candidates
    @candidates.each do |url|
      sleep @delay
      @delay = 30
      puts "... Grabbing #{url}"
      ts = Time.now.to_i

      old_path = "#{@cache}/grabbed/#{@reachable[url]['timestamp']}.html"
      changed  = @reachable[url]['changed']
      info     = @reachable[url] = {'timestamp' => ts,
                                    'changed'   => changed}

      begin
        URI.parse( url)
      rescue URI::InvalidURIError => bang
        info['comment'] = "#{bang.message}"
        next
      end

      response = http_get( url)
      if response.is_a?( Net::HTTPOK)
        ext = 'html'
        if @site.asset?( url)
          ext = url.split('.')[-1]
        end
        File.open( "#{@cache}/grabbed/#{ts}.#{ext}", 'wb') do |io|
          io.write response.body
        end

        if (ext == 'html')
          if File.exist?( old_path)
            if response.body != IO.read( old_path)
              info['changed'] = ts
            end
          end
        end

      elsif response.is_a?( Net::HTTPRedirection)
          url = response['Location']
          # if @config.login_redirect?( url)
          #   info['secured'] = true
          # else
            info['comment']  = url
            info['redirect'] = true
          #end
#        end

      else
        info['comment'] = "#{response.class.name}: #{response.code}"
      end
    end
  end

  def http_get( url, headers = {})
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
    reached( @root)
    @site.include_urls do |url|
      reached( url)
    end
  end

  def reached( url)
    unless @reachable[url]
      @reachable[url] = {'timestamp' => 0, 'changed' => 0}
      @to_trace << url

      info = @pages[url]
      if info
        @reachable[url]['timestamp'] = info['timestamp']
        @reachable[url]['secured']   = true if info['secure']
        @reachable[url]['comment']   = info['comment'] if info['comment']
        @reachable[url]['redirect']  = info['redirect'] if info['redirect']
        @reachable[url]['changed']   = info['changed']
      end
    end
  end

  def save_info
    File.open( "#{@cache}/grabbed.yaml", 'w') do |io|
      io.print @reachable.to_yaml
    end
  end

  def trace?( url)
    return false unless in_site( url)
    @site.trace?( url)
  end

  def trace_from_reachable
    while url = @to_trace.pop
      @links[url].each do |found|
        if trace?( found)
          reached( found)
        end
      end

      if @pages[url] && @pages[url]['redirect']
        reached( @pages[url]['comment'])
      end
    end
  end
end

g = Grabber.new( ARGV[0], ARGV[1])
g.clean_cache
puts "... Initialised #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.find_links
puts "... Found links #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.initialise_reachable
g.trace_from_reachable
puts "... Traced out  #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.check_files_deleted
g.get_candidates( ARGV[2].to_i, ARGV[3])
g.grab_candidates
puts "... Grabbed     #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.save_info
puts "... Saved info  #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"

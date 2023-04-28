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
    @log       = File.open( cache + '/grabber.log', 'w')
  end

  def check_files_deleted
    @reachable.each_pair do |url, page|
      next if page['secured']
      next if page['comment']
      next if @site.asset?( url)
      next unless local?( url)

      unless File.exist?( @cache + "/grabbed/#{page['timestamp']}.html")
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

  def forget_errors
    to_delete = []

    @pages.each_pair do |url, info|
      if info['comment'] && (! info['redirect'])
        @log.puts "... Forgetting #{url}"
        to_delete << url
        @refs[url].each do |ref|
          to_delete << ref
        end
      end
    end

    to_delete.uniq.each do |url|
      @log.puts "... Deleting #{url}"
      @pages.delete( url)
      @links.delete( url)
      @refs.delete( url)
    end

    @log.flush
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

      url1 = url.gsub( ' ', '%20')
      begin
        URI.parse( url1)
      rescue URI::InvalidURIError => bang
        info['comment'] = "#{bang.message}"
        next
      end

      response = nil
      get      = local?( url) && (! @site.asset?( url))
      begin
        response = http_get( url1, get)
      rescue Exception => bang
        info['comment'] = "#{bang.message}"
        next
      end

      if response.is_a?( Net::HTTPOK)
        if get
          File.open( "#{@cache}/grabbed/#{ts}.html", 'wb') do |io|
            io.write response.body
          end

          if File.exist?( old_path)
            if response.body != IO.read( old_path)
              info['changed'] = ts
            end
          end
        end

      elsif response.is_a?( Net::HTTPRedirection)
          url1 = absolutise( url, response['Location'])
          # if @config.login_redirect?( url)
          #   info['secured'] = true
          # else
          if url1
            if get
              info['comment']  = url1
              info['redirect'] = true
            elsif ! similar_url?( url, url1)
              info['comment']  = url1
            end
          else
            info['comment']  = 'Redirect to ' + response['Location']
          end
#        end

      else
        ignore = false
        unless get
          ignore = true if response.is_a?( Net::HTTPRedirection)
          ignore = true if response.is_a?( Net::HTTPForbidden)
          ignore = true if response.is_a?( Net::HTTPMethodNotAllowed)
        end
        info['comment'] = "#{response.class.name}: #{response.code}" unless ignore
      end
    end
  end

  def http_get( url, get)
    uri = URI.parse( url)

    request = get ? Net::HTTP::Get.new(uri.request_uri) : Net::HTTP::Head.new(uri.request_uri)
    request['Accept']          = get ? 'text/html,application/xhtml+xml' : '*/*'
    request['Accept-Language'] = 'en-gb'
    request['User-Agent']      = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'

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
    if m = /^(.*)#/.match( url)
      url = m[1]
    end

    unless @reachable[url]
      @reachable[url] = {'timestamp' => 0, 'changed' => 0}
      @to_trace << url if local?( url)

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

  def reduce_url( url)
    if m = /^https:(.*)$/.match( url)
      url = 'http:' + m[1]
    end

    if m = /^(http:\/\/[a-zA-Z0-9\.\-_]*):\d+(\/.*)$/.match( url)
      url = m[1] + m[2]
    end

    if m = /^(.*)\/\/www\.(.*)$/.match( url)
      url = m[1] + '//' + m[2]
    end

    if m = /^(.*)\/$/.match( url)
      url = m[1]
    end

    url
  end

  def root_url
    @site.root_url
  end

  def save_info
    File.open( "#{@cache}/grabbed.yaml", 'w') do |io|
      io.print @reachable.to_yaml
    end
  end

  def similar_url?( url1, url2)
    url1 = reduce_url( url1)
    url2 = reduce_url( url2)

    if (/\/$/ =~ url1) && (url1 == url2[0...(url1.size)])
      return true
    end

    if m = /^(.*)\/us\/en\/(.*)$/.match( url2)
      return true if url1 == "#{m[1]}/#{m[2]}"
    end

    url1 == url2
  end

  def trace?( url)
    @site.trace?( url)
  end

  def trace_from_reachable
    while url = @to_trace.pop
      @links[url].each do |found|
        if trace?( found)
          reached( found)
        end
      end

      if local?( url) && @pages[url] && @pages[url]['redirect']
        reached( @pages[url]['comment'])
      end
    end
  end
end

g = Grabber.new( ARGV[0], ARGV[1])
puts "... Grabbing #{g.root_url}"
g.clean_cache
puts "... Initialised   #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.find_links
puts "... Found links   #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.forget_errors
puts "... Forgot errors #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.initialise_reachable
g.trace_from_reachable
puts "... Traced out    #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.check_files_deleted
g.get_candidates( ARGV[2].to_i, ARGV[3])
g.grab_candidates
puts "... Grabbed       #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.save_info
puts "... Saved info    #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"

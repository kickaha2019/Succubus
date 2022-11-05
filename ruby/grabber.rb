require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'

require_relative 'processor'

class Grabber
  def initialize( config_dir, cache)
    @config    = Config.new( config_dir)
    @cache     = cache
    @processor = Processor.new( @config, cache)
    @root      = @config.root_url
    #@traced    = {}
    @to_trace  = []
    @reachable = {}
    @delay     = 0
  end

  def add_referral( referral, url)
    return unless referral
    refs = @reachable[url]['referrals']
    return if refs.size > 3
    refs << referral unless (refs.include?( referral) || (referral == url))
  end

  # def add_referrals( referrals, url)
  #   referrals.each do |ref|
  #     add_referral( ref, url)
  #   end
  # end

  def check_files_deleted
    @reachable.each_pair do |url, page|
      next if page['redirect']
      next if page['secured']
      next if page['comment']

      ext = 'html'
      if @config.site.asset?( url)
        ext = url.split('.')[-1]
      end
      unless File.exist?( @cache + "/grabbed/#{page['timestamp']}.#{ext}")
        page['timestamp'] = 0
      end
    end
  end

  def clean_cache
    extant = {}
    @reachable.each_value {|page| extant[page['timestamp'].to_i] = true}

    to_delete = []
    Dir.entries( @cache + '/grabbed').each do |f|
      if m = /^(\d+)\.\w*$/.match( f)
        to_delete << f unless extant[ m[1].to_i]
      end
    end

    to_delete.each do |f|
      File.delete( "#{@cache}/grabbed/#{f}")
    end
  end

  def digest
    @processor.subprocess 'digest'
  end

  def get_candidates( limit, explicit)
    if explicit
      @candidates = [explicit]
      return
    end

    must, recent, poss = [], [], []
    months3 = Time.now.to_i - 90 * 24 * 60 * 60

    @reachable.each_pair do |url, info|
      if @config.site.asset? url
        if info['timestamp'] == 0
          must << url
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
      referers = @reachable[url]['referrals']
      changed  = @reachable[url]['changed']
      info     = @reachable[url] = {'timestamp' => ts,
                                    'referrals' => referers,
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
        if @config.site.asset?( url)
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
        # handled = false
        # if unify(response['Location']) == url
        #   response2 = http_get( response['Location'])
        #   if response2.is_a?( Net::HTTPOK)
        #     File.open( "#{@cache}/grabbed/#{ts}.html", 'wb') do |io|
        #       io.write response2.body
        #     end
        #     handled = true
        #   end
        # end

#        unless handled
          url = response['Location']
          if @config.login_redirect?( url)
            info['secured'] = true
          else
            info['comment']  = url
            info['redirect'] = true
          end
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
    reached( nil, @root)
    @config.include_urls do |url|
      reached( nil, url)
    end
  end

  def reached( referral, url)
    #url = unify( url)

    unless @reachable[url]
      @reachable[url] = {'timestamp' => 0, 'referrals' => [], 'changed' => 0}
      @to_trace << url

      info = @processor.lookup( url)
      if info
        #add_referrals( info.referrals, url)
        @reachable[url]['timestamp'] = info.timestamp
        @reachable[url]['redirect']  = true if info.redirect?
        @reachable[url]['secured']   = true if info.secure?
        @reachable[url]['comment']   = info.comment if info.comment
        @reachable[url]['changed']   = info.changed
      end
    end

    add_referral( referral, url)
  end

  def save_info
    # @reachable.each_value do |info|
    #   info['referrals'] = info['referrals'].uniq.select {|ref| ref && (ref.strip != '')} if info['referrals']
    # end
    File.open( "#{@cache}/grabbed.yaml", 'w') do |io|
      io.print @reachable.to_yaml
    end
  end

  # def to_trace
  #   pages do |url|
  #     next if @traced[url]
  #     return url if @reachable[url]
  #   end
  #   nil
  # end

  def trace?( url)
    return false unless @config.in_site( url) # @root == url[0...(@root.size)]
    true
  end

  def trace_from_reachable
    while url = @to_trace.pop
      info = @processor.lookup( url)
      next if info.nil?
      next if info.timestamp == 0
      #p ['trace_from_reachable2', url, asset?( url)]

      if info.redirect?
        reached( url, info.comment)
        next
      end
      next if info.error?
      next if info.asset?

      info.links do |found|
        if trace?( found)
          # if /allnews\?created/ =~ found
          #   p [url, path, found]
          #   raise 'Ouch'
          # end
          reached( url, found)
        end
      end
    end

    # p @reachable
    # raise 'Dev'
  end
end

g = Grabber.new( ARGV[0], ARGV[1])
puts "... Initialised #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.digest
puts "... Digested    #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.initialise_reachable
g.trace_from_reachable
puts "... Traced out  #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.check_files_deleted
g.get_candidates( ARGV[2].to_i, ARGV[3])
g.grab_candidates
puts "... Grabbed     #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"
g.clean_cache
g.save_info
puts "... Saved info  #{Time.now.strftime( '%Y-%m-%d %H:%M:%S')}"

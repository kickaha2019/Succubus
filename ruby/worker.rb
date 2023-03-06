require 'yaml'

require_relative 'processor'

class Worker < Processor
  def initialize( config_dir, cache)
    @config = Config.new( config_dir)
    super( @config, cache)
  end

  def absolutise( page_url, url)
    return nil if url.nil?
    url = url.strip.sub( /#.*$/, '')
    url = url[2..-1] if /^\.\// =~ url
    return nil if url == ''

    url = url.strip.gsub( '%20', ' ').gsub( '\\', '/')
    url = url.gsub( /.\/\//) do |match|
      (match == '://' ? match : match[0..1])
    end

    root_url = @config.root_url
    dir_url  = page_url.split('?')[0]

    if /^\?/ =~ url
      return dir_url + url
    end

    if /\/$/ =~ dir_url
      dir_url = dir_url[0..-2]
    else
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    while /^\.\.\// =~ url
      url     = url[3..-1]
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    if /^\// =~ url
      url = root_url + url[1..-1]
    elsif /^\w*:/ =~ url
    else
      url = dir_url + '/' + url
    end

    old_url = ''
    while old_url != url
      old_url = url
      url = url.sub( /\/[a-z0-9_\-]+\/\.\.\//i, '/')
    end

    url1 = url.sub( /^http:/, 'https:')
    if local?(url1)
      url = url1
    end

    url
  end

  def find_links( url, parsed, debug)
    parsed.children.each do |node|
      if node.name.upcase == 'A'
        find_links1( url, node['href'])
      elsif node.name.upcase == 'IMG'
        find_links1( url, node['src'])
      elsif node.name.upcase == 'STYLE'
        node.content.scan( /url\s*\(\s*"([^"]*)"\s*\)\s*/im) do |found|
          find_links1( url, found[0])
        end
      end
      find_links( url, node, debug)
    end
  end

  def find_links1( url, link)
    target = absolutise( url, link)
    if target && local?( target)
      @output.puts "#{url}\t#{target}"
    end
  end

  def loop( verb, counter, every)
    @pages.each_pair do |url, info|
      next if info['redirect'] || asset?(url)
      debug = @config.debug_url?( url)

      path = @cache + "/grabbed/#{info['timestamp']}.html"
      next unless File.exist?( path)

      if counter == 0
        step( verb, url, info, parse( path), debug)
        counter = every - 1
      else
        counter -= 1
      end
    end
  end

  def process( verb, counter, every)
    setup( verb, counter)
    loop( verb, counter, every)
    teardown( verb, counter)
  end

  def setup( verb, counter)
    if verb == 'find_links'
      @output = File.open( @cache + "/#{counter}.txt", 'w')
    end
  end

  def step( verb, url, info, parsed, debug)
    if verb == 'find_links'
      find_links( url, parsed.root, debug)
    end
  end

  def teardown( verb, counter)
    if verb == 'find_links'
      @output.close
    end
  end
end

d = Worker.new( ARGV[0], ARGV[1])
d.process( ARGV[2], ARGV[3].to_i, ARGV[4].to_i)

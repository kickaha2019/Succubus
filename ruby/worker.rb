require 'yaml'

require_relative 'processor'

class Worker < Processor
  def initialize( site_file, cache)
    super
  end

  def w_find_classes(url, parsed, found)
    parsed.children.each do |node|
      if node['class']
        node['class'].split( /\s/).each do |clazz|
          found[clazz] = true
        end
      end
      w_find_classes(url, node, found)
    end
  end

  def w_find_links(url, parsed, debug)
    parsed.children.each do |node|
      if @site.respond_to?( :on_node)
        @site.on_node( node) do |ref|
          w_find_links1(url, ref)
        end
      end
      if node.name.upcase == 'A'
        w_find_links1(url, node['href'])
      elsif node.name.upcase == 'IMG'
        w_find_links1(url, node['src'])
      elsif node.name.upcase == 'STYLE'
        node.content.scan( /url\s*\(\s*"([^"]*)"\s*\)\s*/im) do |found|
          w_find_links1(url, found[0])
        end
      end
      w_find_links(url, node, debug)
    end
  end

  def w_find_links1(url, link)
    target = absolutise( url, link)
    if target && (/^http(s):/ =~ target) # && local?( target)
      @output.puts "#{url}\t#{target}"
    end
  end

  def loop( verb, counter, every)
    @pages.each_pair do |url, info|
      debug = @site.debug_url?( url)
      path  = @cache + "/grabbed/#{info['timestamp']}.html"
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
    if verb == 'find_classes'
      @output = File.open( @cache + "/classes#{counter}.txt", 'w')
    elsif verb == 'find_links'
      @output = File.open( @cache + "/links#{counter}.txt", 'w')
    end
  end

  def step( verb, url, info, parsed, debug)
    if verb == 'find_classes'
      found = {}
      w_find_classes(url, parsed.root, found)
      found.keys.each do |clazz|
        @output.puts "#{url}\t#{clazz}"
      end
    elsif verb == 'find_links'
      w_find_links(url, parsed.root, debug) if @site.find_links?( url, parsed.root)
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

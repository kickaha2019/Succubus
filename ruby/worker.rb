require 'yaml'

require_relative 'processor'

class Worker < Processor
  def initialize( site_file, cache)
    super
  end

  def find_links( url, parsed, debug)
    parsed.children.each do |node|
      if @site.respond_to?( :on_node)
        @site.on_node( node) do |ref|
          find_links1( url, ref)
        end
      end
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
      next if info['redirect'] || @site.asset?(url)
      debug = @site.debug_url?( url)

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

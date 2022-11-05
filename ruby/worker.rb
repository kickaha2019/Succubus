require 'yaml'

require_relative 'processor'

class Worker < Processor
  def initialize( config_dir, cache)
    @config   = Config.new( config_dir)
    super( @config, cache)
    @digested = {}
    @dir      = @config.temp_dir

    unless File.exist?( @dir)
      Dir.mkdir( @dir)
    end
  end

  def compile( url, parsed, debug)
    n = 0
    info = lookup( url)

    parsed.tree do |child|
      if child.is_a?( Elements::Article)
        child.index = info.article(n).index
        if @generator.article( url, child, @generation[url]['output'][n])
          raise "Error compiling #{url}: #{child.title}"
        end
        n += 1
      end
    end
  end

  def digest( url, parsed, debug)
    entry = @digested[url] = {'articles' => [], 'links' => []}

    parsed.tree do |child|
      if child.is_a?( Elements::Article)
        entry['articles'] << (article = {'index' => child.index, 'mode' => child.mode.to_s})
        if child.date
          article['date'] = child.date.strftime( '%Y-%m-%d')
        end
        article['title'] = child.title
      end
    end

    parsed.links do |found|
      entry['links'] << found
    end

    entry['error'] = parsed.content?
    parsed.tree do |child|
      child_error, child_msg = child.error?
      if child_error
        p ['digest', child.index, child.class.to_s, child_msg] if debug
        entry['error'] = true
      end
    end

    parsed.advises do |advice|
      article = {'index' => advice[:index],
                 'title' => advice[:title],
                 'date'  => advice[:date].strftime( '%Y-%m-%d'),
                 'mode'  => 'post'}
      @digested['advise:' + advice[:url]] = article
    end
  end

  def dump( struct, filename, debug=false)
    File.open( filename, 'w') do |io|
      io.puts <<"DUMP1"
<html><head>
<style>
.indent {font-family: courier; font-size: 30px; width: 20px; height: 20px; display: inline-block;
         cursor: pointer}
.label {font-size: 20px; height: 20px}
.grokked {background: lime}
.grokked_and_content {background: yellow}
.error {background: red}
.section {background: cyan}
</style>
<script>
function expand( index) {
  document.getElementById( 'e' + index).style.display = 'inline';
  document.getElementById( 'r' + index).style.display = 'none';
  document.getElementById( 'd' + index).style.display = 'block';
}
function reduce( index) {
  document.getElementById( 'e' + index).style.display = 'none';
  document.getElementById( 'r' + index).style.display = 'inline';
  document.getElementById( 'd' + index).style.display = 'none';
}
</script>
</head>
<body><div>
DUMP1
      dump_structure( struct, 0, dump_expand( struct, debug), io)
      io.puts <<"DUMP2"
<div><body></html>
DUMP2
    end
  end

  def dump_expand( struct, debug=false)
    expand, focus = {}, {}
    struct.tree do |element|
      if element.error?
        focus[element.id] = true
      elsif element.is_a?( Elements::Article)
        focus[element.id] = true
      end
      p ['dump_expand1', element.id, focus[element.id]] if debug && focus[element.id]

      element.contents.each do |child|
        expand[element.id] = true if expand[child.id] || focus[child.id]
      end
    end

    if debug
      p ['dump_expand2', expand, focus]
    end

    expand
  end

  def dump_structure( struct, indent, expand, io)
    if indent > 0
      (0...indent).each do
        io.print "<div class=\"indent\"></div>"
      end
    end

    io.print "<div class=\"indent\">"
    before, after = '', ''
    exp = expand[struct.id]

    if struct.contents.size > 0
      io.print "<span id=\"r#{struct.id}\"#{exp ? ' style="display: none"' : ''} onclick=\"expand(#{struct.id})\">&rtri;</span>"
      io.print "<span id=\"e#{struct.id}\"#{exp ? '' : ' style="display: none"'} onclick=\"reduce(#{struct.id})\">&dtri;</span>"
      before = "<div id=\"d#{struct.id}\"#{exp ? '' : ' style="display: none"'}>"
      after  = '</div>'
    end
    io.print "</div>"

    scheme, tooltip = '', false, ''
    struct_error, tooltip = struct.error?

    if struct_error
      scheme = 'error'
    elsif struct.article?
      scheme = 'section'
    elsif struct.grokked?
      if struct.content?
        scheme = 'grokked_and_content'
      else
        scheme = 'grokked'
      end
    else
      if struct.content?
        scheme  = 'error'
        tooltip = 'Ungrokked content'
      end
    end

    # if struct.doc.name == 'nav'
    #   p [struct.doc.name, scheme, struct.class.name, struct.grokked?, struct.content?]
    # end

    io.print "<span class=\"label #{scheme}\" title=\"#{struct.tooltip}#{tooltip}\">"
    io.print( struct.describe)
    io.puts "</span><br>"

    io.puts before
    struct.contents.each do |child|
      dump_structure(  child, indent+1, expand, io)
    end
    io.puts after
  end

  def loop( verb, counter, every)
    pages do |url|
      info = @pages[url]
      next if info['redirect'] || asset?(url)
      debug = @config.debug_url?( url)

      path = @cache + "/grabbed/#{info['timestamp']}.html"
      next unless File.exist?( path)

      if counter == 0
        step( verb, url, info, parse( url, info), debug)
        counter = every - 1
      else
        counter -= 1
      end
    end
  end

  def process( verb, counter, every)
    setup( verb)
    loop( verb, counter, every)
    teardown( verb, counter)
  end

  def setup( verb)
    if verb == 'compile'
      @output_dir = @config.output_dir
      @generation = YAML.load( IO.read( @config.dir + '/generation.yaml'))
      @generator  = @config.generator
      @generator.record_generation( @generation)
    end
  end

  def step( verb, url, info, parsed, debug)
    if verb == 'compile'
      compile( url, parsed, debug)
    end

    if verb == 'digest'
      digest( url, parsed, debug)
    end

    if verb == 'dump'
      digest( url, parsed, debug)
      dump( parsed, @dir + "/#{info['timestamp']}.html", debug)
    end
  end

  def teardown( verb, counter)
    if (verb == 'digest') || (verb =='dump')
      File.open( "#{@dir}/digest#{counter}.yaml", 'w') do |io|
        io.puts @digested.to_yaml
      end
    end
  end
end

d = Worker.new( ARGV[0], ARGV[1])
d.process( ARGV[2], ARGV[3].to_i, ARGV[4].to_i)

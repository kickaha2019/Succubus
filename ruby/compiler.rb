require_relative 'processor'

class Compiler
  def initialize( config_dir, cache)
    @config     = Config.new( config_dir)
    @cache      = cache
    @processor  = Processor.new( @config, cache)
    @output_dir = @config.output_dir
    @generator  = @config.generator
    @generation = {}
    @gen_paths  = {}
  end

  def compile
    @processor.subprocess( 'digest')
    copy_assets unless @config.leech_assets?
    prepare_generation
    @generator.record_generation( @generation)
    @processor.subprocess( 'compile')
    @generator.site
  end

  def copy_assets
    @processor.pages do |url|
      info = @processor.lookup(url)
      next if info.error? || info.redirect? || (info.timestamp == 0)

      if info.asset?
        cached = "#{@cache}/grabbed/#{info.timestamp}.#{url.split('.')[-1]}"
        output = @generator.copy_asset( cached, url.gsub( /[\(\)]/, '_'))
        @generation[url] = {'output' => output}
      end
    end
  end

  def prepare_generation
    @processor.pages do |url|
      info = @processor.lookup( url)
      next if info.asset? || info.error? || (info.timestamp == 0)

      if info.redirect?
        @generation[url] = {'redirect' => @processor.deref(url)}
      elsif info.articles?
        @generator.register_page( info)
        @generation[url] = {'output' => prepare_output( info)}
      end
    end

    File.open( @config.dir + '/generation.yaml', 'w') do |io|
      io.print @generation.to_yaml
    end
  end

  def prepare_output( page)
    unique = 1
    while true do
      output = @generator.output_path( page.url, page, (unique == 1) ? '' : "-#{unique}")
      if @gen_paths[output]
        unique += 1
      else
        @gen_paths[output] = true
        return output
      end
    end
  end
end

c = Compiler.new( ARGV[0], ARGV[1])
c.compile


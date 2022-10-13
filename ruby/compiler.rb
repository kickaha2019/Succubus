require_relative 'processor'

class Compiler < Processor
  def initialize( config, cache)
    super( config, cache)
    @output_dir = @config['output_dir']
    require_relative( 'generators/' + @config['generator'])
    @generator  = Kernel.const_get( 'Generators::' + @config['generator']).new( config, @config, {})
    @generation = {}
    @gen_paths  = {}
  end

  def compile
    subprocess( 'digest')
    copy_assets
    prepare_generation
    subprocess( 'compile')
    @generator.site
  end

  def copy_assets
    pages do |url|
      info = lookup(url)
      next if info.error? || info.redirect? || (info.timestamp == 0)

      if info.asset?
        cached = "#{@cache}/grabbed/#{info.timestamp}.#{url.split('.')[-1]}"
        output = @generator.copy_asset( cached, url.gsub( /[\(\)]/, '_'))
        @generation[url] = {'output' => output}
      end
    end
  end

  def prepare_generation
    pages do |url|
      info = lookup( url)

      if info.redirect?
        @generation[url] = {'redirect' => deref(url)}
      else
        outputs = []
        @generation[url] = {'output' => outputs}
        info.articles do |article|
          @generator.register_article( url, article)
          outputs << prepare_output( url, article)
        end

        info.links do |found|
          if found != unify(found)
            @generation[found] = {'redirect' => deref(unify(found))}
          end
        end
      end
    end

    File.open( @config_dir + '/generation.yaml', 'w') do |io|
      io.print @generation.to_yaml
    end
  end

  def prepare_output( url, article)
    unique = 1
    while true do
      output = @generator.output_path( url, article, (unique == 1) ? '' : "-#{unique}")
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


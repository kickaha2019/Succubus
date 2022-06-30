require_relative 'processor'

class Compiler < Processor
  def initialize( config, cache, output_dir)
    super( config, cache)
    require_relative( 'generators/' + @config['generator'])
    @generator = Kernel.const_get( 'Generators::' + @config['generator']).new( @config, output_dir)
  end

  def compile
    preparse_all
    compile_site
  end

  def compile_site
    @generator.site_begin
    @site.taxonomies do |singular, plural|
      @generator.site_taxonomy( singular, plural)
    end
    @generator.site_end
  end
end

c = Compiler.new( ARGV[0], ARGV[1], ARGV[2])
c.compile


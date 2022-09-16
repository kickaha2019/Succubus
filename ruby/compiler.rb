require_relative 'processor'

class Compiler < Processor
  def initialize( config, cache, output_dir)
    super( config, cache)
    require_relative( 'generators/' + @config['generator'])
    @errors     = false
    @output_dir = output_dir
    @generator  = Kernel.const_get( 'Generators::' + @config['generator']).new( config, @config, output_dir)
    @generated  = []
    @comments   = Hash.new {|h,k| h[k] = 0}
    @generated << "Original\tCompiled\tComment"
  end

  def clean_old_files
    @generator.clean_old_files
  end

  def compile
    preparse_all
    compile_site
    @generator.write_file( @config_dir + '/generated.csv',
                           @generated.join( "\n"))

    @comments.each_pair do |k,v|
      puts "... #{k}: #{v}"
    end

    if @generator.error?
      puts "*** Compilation errors"
      exit 1
    end
    clean_old_files
  end

  def compile_article( timestamp, url, article)
    generated, comment = @generator.article( "#{@cache}/#{timestamp}.html", url, article)
    @generated << "#{url}\t#{generated}\t#{comment}"

    comment.split( ' ').each do |word|
      @comments[word] += 1
    end
  end

  def compile_pages
    @pages.each_pair do |url, info|
      _, error, _, _, parsed = examine( url)
      next unless parsed && (! error)

      parsed.tree do |child|
        if child.is_a?( Elements::Article)
          compile_article( info['timestamp'], url, child)
        end
      end
    end
  end

  def compile_site
    @generator.site_begin
    page_redirects
    copy_assets
    precompile_pages
    compile_pages
    @generator.site_end
  end

  def copy_assets
    @pages.each_pair do |url, info|
      asset, error, redirect, _, _ = examine( url)
      next unless asset && (! error) && (! redirect)
      next unless info['timestamp'] > 0
      @generator.asset_copy( "#{@cache}/#{info['timestamp']}.#{url.split('.')[-1]}", url)
    end
  end

  def page_redirects
    @pages.each_pair do |url, info|
      asset, error, redirect, _, _ = examine( url)
      next unless (! error) && redirect
      @generator.redirect( url, info['comment'])
    end
  end

  def precompile_pages
    @pages.each_pair do |url, info|
      _, error, _, _, parsed = examine( url)
      next unless parsed && (! error)

      parsed.tree do |child|
        if child.is_a?( Elements::Article)
          @generator.register_article( url, child)
        end
      end
    end
  end
end

c = Compiler.new( ARGV[0], ARGV[1], ARGV[2])
c.compile


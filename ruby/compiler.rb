require_relative 'processor'

class Compiler < Processor
  def initialize( config, cache, output_dir)
    super( config, cache)
    require_relative( 'generators/' + @config['generator'])
    @errors     = false
    @output_dir = output_dir
    @generator  = Kernel.const_get( 'Generators::' + @config['generator']).new( config, @config, output_dir)
    @generated  = File.open( output_dir + '/content/generated.html', 'w')
    @generated.puts <<"HEADER"
<html>
<head>
</head>
<body><center><table>
<tr><th>Origin</th><th>Generated</th><th>Comment</th></tr>
HEADER
  end

  def clean_old_files
    @generator.clean_old_files
  end

  def compile
    preparse_all
    compile_site
    @generated.puts '</table></center></body></html>'
    @generated.close

    if @generator.error?
      puts "*** Compilation errors"
      exit 1
    end
    clean_old_files
  end

  def compile_article( timestamp, url, article)
    @generator.article_begin( "#{@cache}/#{timestamp}.html", url, article)
    if article.date
      @generator.article_date( article.date)
    end
    if article.title
      @generator.article_title( article.title)
    end
    @generator.article_tags( article.tags ? article.tags : {})
    @generator.article_description( article.description)
    md = article.generate( @generator)
    generated, comment = @generator.article_end( md)
    @generated.puts <<"LINE"
<tr>
<td><a href="#{url}">#{url}</a></td>
<td><a href="#{generated}">#{generated}</a></td>
<td>#{comment}</td>
</tr>
LINE
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
    @site.taxonomies do |singular, plural|
      @generator.site_taxonomy( singular, plural)
    end
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


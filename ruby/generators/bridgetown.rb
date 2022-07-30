module Generators
  class Bridgetown
    def initialize( config_dir, config, output_dir)
      @config_dir    = config_dir
      @config        = config
      @output_dir    = output_dir
      @taxonomies    = {}
      @written       = {}
      @generated     = {}
      @article_error = false
      @any_errors    = false
      @article_url   = nil
      @path2article  = {}
      @enc2names     = {}

      # Control the markdown generation
      @indent        = ['']
      @list_marker   = '#'
      @table_state   = nil
    end

    def asset_copy( cached, url)
      path = @output_dir + '/images/' + url[(@config['root_url'].size)..-1]
      @generated[path] = true
      unless File.exist?( path)
        create_dir( File.dirname( path))
        unless system( "cp #{cached} #{path}")
          raise "Error copying  #{cached} to #{path}"
        end
      end
    end

    def article_begin( url, article)
      @article_url   = url
      @article_error = false
      @path          = output_path( url, article)
      @front_matter  = {'layout'     => 'default'}
      @markdown      = []

      if fm = @config['bridgetown']['front_matter'][article.mode.to_s]
        fm.each_pair {|k,v| @front_matter[k] = v}
      end

      if @written[@path]
        error( "Duplicate output path for #{url} and #{@written[@path]}")
      end
      @written[@path] = url
    end

    def article_date( date)
      @front_matter['date'] = date.strftime( '%Y-%m-%d')
    end

    def article_end
      write_file( @path, "#{@front_matter.to_yaml}\n---\n#{@markdown.join('')}")
    end

    def article_tags( tags)
      @front_matter['categories'] = tags
    end

    def article_title( title)
      @front_matter['title'] = title
    end

    def blockquote_begin
      @indent << @indent[-1] + ' < '
    end

    def blockquote_end
      @indent.pop
    end

    def cell( text)
      unless /\|$/ =~ @markdown[-1]
        @markdown << '|'
      end
      @markdown << text.gsub( '|', '\\|')
      @markdown << '|'
    end

    def clean_old_files
      clean_old_files1( @output_dir + '/src/_posts')
      clean_old_files1( @output_dir + '/src')
    end

    def clean_old_files1( dir)
      empty = true

      Dir.entries( dir).each do |f|
        next if /^[\._]/ =~ f
        path = dir +'/' + f

        if File.directory?( path)
          if clean_old_files1( path)
            begin
              File.delete( path)
            rescue
            end
          else
            empty = false
          end
        elsif @generated[path]
          empty = false
        else
          File.delete( path)
        end
      end

      empty
    end

    def copy_template( template_path, dest_path)
      data = IO.read( @config_dir + '/templates/' + template_path)
      write_file( @output_dir + '/' + dest_path, data)
    end

    def create_dir( dir)
      unless File.exist?( dir)
        create_dir( File.dirname( dir))
        Dir.mkdir( dir)
      end
    end

    def disambiguate_path( stem, article)
      index = 1
      stem  = stem.split('?')[0]
      path  = stem
      while @path2article[path] && (@path2article[path] != article)
        index += 1
        path   = stem + "-#{index}"
      end
      @path2article[path] = article
      path
    end

    def e( name)
      encoded = name.gsub( /\W/, '_')
      @enc2names[encoded] = name
      encoded
    end

    def error( msg)
      unless @article_error
        @article_error = true
        puts "*** #{msg} in #{@article_url}"
      end
      @any_errors = true
    end

    def error?
      @any_errors
    end

    def heading_begin( level)
      newline
      @markdown << ('######'[0...level] + ' ')
    end

    def heading_end( level)
      newline
    end

    def hr
      @markdown << "---\n"
    end

    def image( src, title)
      newline
      @markdown << "![#{title}](#{src})\n"
    end

    def link( text, href)
      return unless text && text.strip != ''
      @markdown << "[#{text.strip}](#{href})"
    end

    def link_text_only?
      true
    end

    def list_begin( type)
      @list_marker = (type == :ordered) ? 1 : '#'
    end

    def list_item_begin
      if @list_marker.is_a?( Integer)
        indent = "#{@list_marker}. "
        @list_marker += 1
      else
        indent = '- '
      end
      newline
      @markdown << indent
      @indent << @indent[-1] + "          "[0...(indent.size)]
    end

    def list_item_end
      @indent.pop
    end

    def list_end( type)
    end

    def method_missing( verb, *args)
      error( verb.to_s + ": ???")
    end

    def newline( force = false)
      force = true unless @markdown[-1] && @markdown[-1][-1] == "\n"
      if force
        @markdown << ("\n" + @indent[-1])
      end
    end

    def output_path( url, article)
      if article.root
        return @output_dir + '/src/index.md'
      end

      if article.mode == :post
        stem = @output_dir +
               '/src/_posts/' +
               "#{article.date.strftime( '%Y-%m-%d')}-#{e(article.title)}"
        return disambiguate_path( stem, article) + '.md'
      end

      stem = @output_dir + '/src/' + article.relative_url.sub( /\.[a-z]*$/i, '')
      disambiguate_path( stem, article) + '.md'
    end

    def paragraph_begin
      newline
      newline( true)
    end

    def paragraph_end
      newline
      newline( true)
    end

    def pre_begin
      newline
      @markdown << @indent[-1] + "~~~\n"
    end

    def pre_end
      pre_begin
    end

    def register_article( url, article)
    end

    def row_begin
      @cell_count = 0
      newline
    end

    def row_end
      if @table_state == :header
        newline
        @markdown << '|'
        (0...@cell_count).each {@markdown << '-|'}
        @table_state = :data
      end
    end

    def site_begin
      copy_template( 'bridgetown/footer.liquid', 'src/_components/footer.liquid')
      copy_template( 'bridgetown/head.liquid',   'src/_components/head.liquid')
      copy_template( 'bridgetown/home.liquid',   'src/_layouts/home.liquid')
      copy_template( 'bridgetown/navbar.liquid', 'src/_components/navbar.liquid')
      copy_template( 'bridgetown/site.css',      'src/site.css')
    end

    def site_end
      site_config = @config['bridgetown']['config']
      write_file( @output_dir + '/config.yaml', site_config.to_yaml)
    end

    def site_taxonomy( singular, plural)
      @taxonomies[singular] = plural
    end

    def style_begin( styles)
      styles.each do |style|
        if style == :bold
          @markdown << '**'
        elsif style == :big
        elsif style == :centre
        elsif style == :cite
          @markdown << '**'
        elsif style == :code
        elsif style == :emphasized
          @markdown << '*'
        elsif style == :indent
        elsif style == :italic
          @markdown << '*'
        elsif style == :keyboard
        elsif style == :row
          newline
        elsif style == :small
        elsif style == :superscript
        elsif style == :teletype
        elsif style == :underline
          @markdown << '*'
        elsif style == :variable
          @markdown << '*'
        else
          error( "style_begin: #{styles.collect {|s| s.to_s}.join( ' ')}")
        end
      end
    end

    def style_end( styles)
      styles.each do |style|
        if style == :bold
          @markdown << '**'
        elsif style == :big
        elsif style == :centre
        elsif style == :cite
          @markdown << '**'
        elsif style == :code
        elsif style == :emphasized
          @markdown << '*'
        elsif style == :indent
        elsif style == :italic
          @markdown << '*'
        elsif style == :keyboard
        elsif style == :row
          newline
        elsif style == :small
        elsif style == :superscript
        elsif style == :teletype
        elsif style == :underline
          @markdown << '*'
        elsif style == :variable
          @markdown << '*'
        else
          error( "style_begin: #{styles.collect {|s| s.to_s}.join( ' ')}")
        end
      end
    end

    def table_begin
      @table_state = :header
    end

    def table_end
    end

    def text( str)
      @markdown << str.gsub( /\s*\n/, ' ')
    end

    def write_file( path, data)
      @generated[path] = true
      create_dir( File.dirname( path))
      unless File.exist?( path) && (IO.read( path).strip == data.strip)
        puts "... Writing #{path}"
        File.open( path, 'w') {|io| io.print data}
      end
    end
  end
end
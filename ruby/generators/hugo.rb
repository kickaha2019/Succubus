module Generators
  class Hugo
    def initialize( config, output_dir)
      @config        = config
      @output_dir    = output_dir
      @taxonomies    = {}
      @written       = {}
      @generated     = {}
      @article_error = false
      @article_url   = nil

      # Control the markdown generation
      @indent        = ['']
      @list_marker   = '#'
      @table_state   = nil
    end

    def asset_copy( cached, url)
      path = @output_dir + '/static/' + url[(@config['root_url'].size)..-1]
      @generated[path] = true
      unless File.exist?( path)
        create_dir( File.dirname( path))
        unless system( "cp #{cached} #{path}")
          raise "Error copying  #{cached} to #{path}"
        end
      end
    end

    def article_begin( url)
      @article_url   = url
      @article_error = false
      @path = @output_dir + '/content/' + url[(@config['root_url'].size)..-1]
      if /\/$/ =~ @path
        @path = @path + 'index.html'
      elsif @path.split('/')[-1].split('.').size == 1
        @path = @path + '.html'
      end

      while @written[@path]
        if m = /^(.*)-(\d+)\.html$/.match( @path)
          @path = "#{m[1]}-#{m[2].to_i+1}.html"
        else
          @path = @path[0..-6] + '-2.html'
        end
      end

      @front_matter = {}
      @markdown     = []
    end

    def article_date( date)
      @front_matter['date'] = date.strftime( '%Y-%m-%d')
    end

    def article_end
      write_file( @path, "#{@front_matter.to_yaml}\n---\n#{@markdown.join('')}")
    end

    def article_title( title)
      @front_matter['title'] = title
    end

    def blockquote_begin
      @indent << @indent[-1] + '< >'
    end

    def blockquote_end
      @indent.pop
    end

    def break_begin
    end

    def break_end
      newline
      @markdown << "\n"
    end

    def cell_begin
      unless /\|$/ =~ @markdown[-1]
        @markdown << '|'
      end
    end

    def cell_end
      @markdown << '|'
    end

    def clean_old_files
      clean_old_files1( @output_dir + '/content')
      clean_old_files1( @output_dir + '/static')
    end

    def clean_old_files1( dir)
      empty = true

      Dir.entries( dir).each do |f|
        next if /^\./ =~ f
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

    def create_dir( dir)
      unless File.exist?( dir)
        create_dir( File.dirname( dir))
        Dir.mkdir( dir)
      end
    end

    def error( msg)
      unless @article_error
        @article_error = true
        puts "*** #{msg} in #{@article_url}"
      end
    end

    def heading_begin( level)
      @markdown << "\n#{"######"[0...level]} "
    end

    def heading_end( level)
    end

    def hr
      newline
      @markdown << "---\n"
    end

    def image( src, title)
      newline
      @markdown << "![#{title}](#{src})\n"
    end

    def link_text( href, text)
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

    def newline
      @markdown << ("\n" + @indent[-1]) unless @markdown[-1] && @markdown[-1][-1] == "\n"
    end

    def paragraph_begin
      @markdown << "\n\n" unless @markdown[-1] == "\n\n"
    end

    def paragraph_end
      paragraph_begin
    end

    def preformatted( text)
      text = text.gsub( /\n /, "\\\n\ ")
      text = text.gsub( /\n/, "\\\n")
      text = text.gsub( /\\\\\n/, "\\\n")
      @markdown << text
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
    end

    def site_end
      site_config = @config['hugo']
      site_config['taxonomies'] = @taxonomies
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
      @markdown << str
    end

    def write_file( path, data)
      @generated[path] = true
      create_dir( File.dirname( path))
      unless File.exist?( path) && (IO.read( path).strip == data.strip)
        File.open( path, 'w') {|io| io.print data}
      end
    end
  end
end
module Generators
  class Hugo
    def initialize( config, output_dir)
      @config        = config
      @output_dir    = output_dir
      @taxonomies    = {}
      @written       = {}
      @generated     = {}
      @article_error = false
      @any_errors    = false
      @article_url   = nil
      @url2articles  = Hash.new {|h,k| h[k] = []}
      @enc2names     = {}

      # Control the markdown generation
      @indent        = ['']
      @list_marker   = '#'
      @table_state   = nil

      # Section control
      @sec2articles  = Hash.new {|h,k| h[k] = []}
      @no_taxa_error = false
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

    def article_begin( url, article)
      @article_url   = url
      @article_error = false
      @path          = output_path( url, article)
      @front_matter  = {}
      @markdown      = []

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
      @markdown << "######"[0...level]
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
        return @output_dir + '/content/index.md'
      end

      if @taxonomies.empty?
        error( 'No taxonomies defined') unless @no_taxa_error
        @no_taxa_error = true
        section_taxa = 'Section'
      else
        section_taxa = @taxonomies.keys[0]
      end

      section_tag = article.tags.select {|tag| tag[0] == section_taxa}.collect {|tag| tag[1]}
      section = section_tag.empty? ? 'Pages' : section_tag[0]

      section_dir = @output_dir + '/content/' + e(section)
      if @sec2articles[section].empty?
        write_file( section_dir + '/_index.md', <<"BRANCH")
---
title: #{section}
description: #{section}
---
BRANCH

        write_file( section_dir + '/pages/index.md', <<"LEAF")
---
title: #{section}
description: #{section}
---
LEAF
      end

      if index = @sec2articles[section].index( article)
        index += 1
      else
        @sec2articles[section] << article
        index = @sec2articles[section].size
      end

      section_dir + "/pages/#{index}.md"
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
      @url2articles[url] << article
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
      if @taxonomies.size < 2
        site_config['disableKinds'] = ['taxonomy', 'term']
      else
        site_config['taxonomies'] = @taxonomies[1..-1]
      end
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
        File.open( path, 'w') {|io| io.print data}
      end
    end
  end
end
module Generators
  class Hugo
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

      # Stack to allow for recursive generation
      @saved = []

      # Tag internal names
      @tag2internal  = Hash.new {|h,k| h[k] = "t#{@tag2internal.size}"}

      # Control the markdown generation
      @indent        = ['']
      @list_marker   = '#'
      @table_state   = nil
    end

    def article_begin( url, article)
      @article_url   = url
      @article_error = false
      @path          = output_path( url, article)
      @front_matter  = {'layout'   => (article.mode == :post) ? 'post' : 'article',
                        'toRoot'   => to_root( article),
                        'fromRoot' => from_root( article),
                        'mode'     => article.mode.to_s}
      @markdown      = []

      # if fm = @config['bridgetown']['front_matter'][article.mode.to_s]
      #   fm.each_pair {|k,v| @front_matter[k] = v}
      # end

      if article.mode == :home
        @front_matter['layout'] = 'home'
        generate_posts_page

        unless @taxonomies.empty?
          sections = []
          taxa0 = @taxonomies.keys[0]
          @tag2internal.keys.sort.each do |taxa_tag|
            if taxa_tag[0..taxa0.size] == taxa0 + ':'
              name = taxa_tag[(taxa0.size+1)..-1]
              sections << {'name' => name, 'key' => @tag2internal[taxa_tag]}
            end
          end

          sections.sort_by! {|section| section['name']}
          @front_matter['sectionIndex'] =
              sections.select {|section| section['name'] == 'General'} +
                  sections.select {|section| section['name'] != 'General'}

          sections.each do |section|
            generate_section_page( section['key'], section['name'])
          end
        end
      else
        @front_matter['parents'] = [{'url' => 'index.html', 'title' => 'Home'}]
      end

      if @written[@path]
        error( "Duplicate output path for #{url} and #{@written[@path]}")
      end

      @written[@path] = url
    end

    def article_date( date)
      @front_matter['date'] = date.strftime( '%Y-%m-%d')
    end

    def article_description( text)
      if text && (text != '')
        @front_matter['description'] = (text.size < 30) ? text : text[0..28].gsub( / [^ ]+$/, ' ...')
      end
    end

    def article_end
      write_file( @path, "#{@front_matter.to_yaml}\n---\n#{@markdown.join('')}")
    end

    def article_tags( tags)
      return if @front_matter['section_index']
      taxas, names = {}, {}
      tags.each_pair do |taxa, name|
        taxas[taxa] = @tag2internal[taxa+':'+name]
        names[taxas[taxa]] = name
      end

      @taxonomies.keys.each_index do |i|
        taxa = @taxonomies.keys[i]
        @front_matter["section#{i}"] = taxas[taxa] ? taxas[taxa] : @tag2internal[taxa+':General']
      end

      section = @front_matter["section0"]
      if (@front_matter['mode'] == 'article') || (@front_matter['mode'] == 'post')
        @front_matter['parents'] << {'url'   => 'section-' + section + '/index.html',
                                     'title' => (names[section] ? names[section] : 'General')}
      end

      if @front_matter['mode'] == 'post'
        @front_matter['parents'] << {'url'   => 'section-' + section + '-posts/index.html',
                                     'title' => 'Posts'}
      end
    end

    def article_title( title)
      @front_matter['title'] = title
    end

    def asset_copy( cached, url)
      path = @output_dir + '/content/' + url[(@config['root_url'].size)..-1]
      @generated[path] = true
      unless File.exist?( path)
        create_dir( File.dirname( path))
        unless system( "cp #{cached} #{path}")
          raise "Error copying  #{cached} to #{path}"
        end
      end
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
      data = IO.read( @config_dir + '/' + template_path)
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

    def ensure_index_md( dir)
      return if File.exist?( dir + '/_index.md')
      write_file( dir + '/_index.md', "---\nlayout: default\ntitle: Dummy\n---\n")
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

    def from_root( article)
      return 'index.html' if article.mode == :home
      path = article.relative_url.sub( /\.[a-z]*$/, '')
      unless /(^|\/)index$/ =~ path
        path = path + '/index'
      end
      path + '.html'
    end

    def generate_posts_page
      save_generation
      @path          = @output_dir + '/content/index-posts/_index.md'
      parents        = [{'url'    => 'index.html', 'title' => 'Home'}]
      @front_matter  = {'layout'  => 'home_posts',
                        'toRoot'  => '../',
                        'title'   => 'All posts',
                        'parents' => parents}
      write_file( @path, "#{@front_matter.to_yaml}\n---\n")
      restore_generation
    end

    def generate_section_page( collection, title)
      save_generation
      #@article_url   = @config['root_url'] + "/section-#{collection}.html"
      #@article_error = false
      @path          = @output_dir + '/content/section-' + collection + '.md'
      parents        = [{'url' => 'index.html', 'title' => 'Home'}]
      @front_matter  = {'layout'    => 'section',
                        'toRoot'    => '../',
                        'title'     => title,
                        'parents'   => parents,
                        'section0'  => collection}
      write_file( @path, "#{@front_matter.to_yaml}\n---\n")
      restore_generation
      generate_section_posts_page( collection, title)
    end

    def generate_section_posts_page( section, title)
      save_generation
      @path          = @output_dir + '/content/section-' + section + '-posts/_index.md'
      parents        = [{'url'    => 'index.html', 'title' => 'Home'},
                        {'url'    => 'section-' + section + '/index.html', 'title' => title}]
      @front_matter  = {'layout'   => 'section_posts',
                        'section0' => section,
                        'toRoot'   => '../',
                        'title'    => 'All posts for ' + title,
                        'parents'  => parents}
      write_file( @path, "#{@front_matter.to_yaml}\n---\n")
      restore_generation
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
        return @output_dir + '/content/_index.md'
      end

      stem = @output_dir + '/content/' + article.relative_url.sub( /\.[a-z]*$/i, '').sub( '/index', '/_index')
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

    def raw( html)
      relpath = @article_url[@config['root_url'].size..-1].split('/')
      if relpath.size < 2
        to_root = ''
      else
        to_root = relpath[1..-1].collect {'../'}.join( '')
      end
      @markdown << html.gsub( /src="\//, "src=\"#{to_root}")
    end

    def register_article( url, article)
      article.tags.each_pair do |section, tag|
        @tag2internal[section + ':' + tag]
      end
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

    def restore_generation
      @article_url, @article_error, @path, @front_matter, @markdown = * @saved.pop
    end

    def save_generation
      @saved << [@article_url, @article_error, @path, @front_matter, @markdown]
    end

    def site_begin
      unless system( "rsync -r --delete #{@config_dir}/layouts/ #{@output_dir}/layouts/")
        raise "Error copying layouts"
      end
      copy_template( 'index.css', 'content/index.css')
    end

    def site_end
      site_config = @config['hugo']['config']
      write_file( @output_dir + '/config.yaml', site_config.to_yaml)
      @generated.keys.each do |path|
        ensure_index_md( File.dirname( path))
      end
      toml = @output_dir + '/config.toml'
      File.delete( toml) if File.exist?( toml)
    end

    def site_taxonomy( singular, plural)
      @taxonomies[singular] = plural
    end

    def style_begin( styles)
      styles.each do |style|
        if style == :bold
          @markdown << '**'
        elsif style == :big
        elsif style == :cite
          @markdown << '**'
        elsif style == :code
        elsif style == :emphasized
          @markdown << '*'
        elsif style == :italic
          @markdown << '*'
        elsif style == :keyboard
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
        elsif style == :cite
          @markdown << '**'
        elsif style == :code
        elsif style == :emphasized
          @markdown << '*'
        elsif style == :italic
          @markdown << '*'
        elsif style == :keyboard
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

    def to_root( article)
      path = from_root( article).split('/')
      return '' if path.size < 2
      path[1..-1].collect {'../'}.join( '')
    end

    def write_file( path, data)
      error( path + ': already written') if @generated[path]
      @generated[path] = true
      create_dir( File.dirname( path))
      unless File.exist?( path) && (IO.read( path).strip == data.strip)
        puts "... Writing #{path}"
        File.open( path, 'w') {|io| io.print data}
      end
    end
  end
end
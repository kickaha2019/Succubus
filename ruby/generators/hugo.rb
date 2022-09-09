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
      @line_start    = false
      @list_marker   = '#'
      @table_state   = nil
    end

    def article_begin( cached, url, article)
      @article_url   = url
      @article_error = false
      @path          = output_path( url, article)
      @front_matter  = {'layout'   => (article.mode == :post) ? 'post' : 'article',
                        'mode'     => article.mode.to_s,
                        'origin'   => url,
                        'cache'    => cached}
      @comment       = []
      @line_start    = true

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
        @front_matter['parents'] = [{'url' => '/index.html', 'title' => 'Home'}]
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

    def article_end( markdown)
      write_file( @path, "#{@front_matter.to_yaml}\n---\n#{markdown.join('')}")
      wrote = @path[(@output_dir.size+9)..-1].sub( /\.md$/, '.html').sub( '_index', 'index')
      unless /\/(_|)index\.html$/ =~ wrote
        wrote = wrote.sub( /\.html$/, '/index.html')
      end
      return wrote, raw?( markdown) ? 'Raw' : ''
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
        @front_matter['parents'] << {'url'   => '/section-' + section + '/index.html',
                                     'title' => (names[section] ? names[section] : 'General')}
      end

      if @front_matter['mode'] == 'post'
        @front_matter['parents'] << {'url'   => '/section-' + section + '-posts/index.html',
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

    def blockquote( md)
      ["\n"] + strip(md).collect {|line| '< ' + line} + ["\n"]
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

    def description_list( list)
      ["\n"] + list.collect do |entry|
        [entry[0][0] + "\n"] +
        entry[1..-1].collect {|text| [': ' + text[0] + "\n"]}
      end.flatten + ["\n"]
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
      if File.exist?( dir + '.md')
        write_file( dir + '/_index.md', IO.read( dir + '.md'))
        File.delete( dir + '.md')
      else
        return if File.exist?( dir + '/_index.md')
        write_file( dir + '/_index.md', "---\nlayout: default\ntitle: Dummy\n---\n")
      end
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

    def generate_posts_page
      save_generation
      @path          = @output_dir + '/content/index-posts/_index.md'
      parents        = [{'url'    => '/index.html', 'title' => 'Home'}]
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
      parents        = [{'url' => '/index.html', 'title' => 'Home'}]
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
      parents        = [{'url'    => '/index.html', 'title' => 'Home'},
                        {'url'    => '/section-' + section + '/index.html', 'title' => title}]
      @front_matter  = {'layout'   => 'section_posts',
                        'section0' => section,
                        'toRoot'   => '../',
                        'title'    => 'All posts for ' + title,
                        'parents'  => parents}
      write_file( @path, "#{@front_matter.to_yaml}\n---\n")
      restore_generation
    end

    def heading( level, markdown)
      ["\n"] +
      strip(markdown).collect {|line| '######'[0...level] + ' ' + line} +
      ["\n"]
    end

    def hr
      ["---\n"]
    end

    def image( src, title)
      ["![#{title}](#{localise(src)})"]
    end

    def link( text, href)
      return [] unless text && ! text.empty?
      ["[#{text.join(' ')}](#{localise href})"]
    end

    def link_text_only?
      true
    end

    def list( type, items)
      items = items.collect do |item|
        item.select {|line| line && line.strip != ''} #.collect {|line| line.rstrip}
      end

      items = items.select {|item| ! item.empty?}

      if type == :ordered
        out = []
        items.each_index do |i|
          item = items[i]
          indent = "          "[0...((i+1).to_s.size+2)]
          out << ["#{i+1}. " + item[0] + "\n"] +
              item[1..-1].collect {|line| indent + line + "\n"}
        end
        ["\n"] + out.flatten + ["\n"]
      else
        ["\n"] + items.collect do |item|
          ['- ' + item[0] + "\n"] +
              item[1..-1].collect {|line| '  ' + line + "\n"}
        end.flatten + ["\n"]
      end
    end

    def localise(url)
      # if /pairs19a-s.jpg/ =~ url
      #   p ['localise?1', url, @config['root_url']]
      # end
      url0, url = url, url.strip.sub( /^http:/, 'https:')
      root_url = @config['root_url'].sub( /^http:/, 'https:')

      if /^\// =~ url
        url = root_url + url[1..-1]
      elsif /^https:/ =~ url
      elsif m = /(^.*\/)[^\/]*\.html$/.match( @article_url)
        url = m[1].sub( /^http:/, 'https:') + url
      else
        url = @article_url.sub( /^http:/, 'https:') + '/' + url
      end

      # if /pairs19a-s.jpg/ =~ url
      #   p ['localise?2', url, @article_url]
      # end

      return url0 unless url[0...(root_url.size)] == root_url
      url = url[(root_url.size-1)..-1]

      if /#/ =~ url
        url = url.split( '#')[0]
      end

      if m = /\.([a-z]*)$/i.match( url)
        if m[1] == 'html'
          unless /\/index.html$/ =~ url
            url = url.sub( /\.html$/, '/index.html')
          end
        end
      else
        url += '/index.html'
      end

      # if /pairs19a-s.jpg/ =~ url
      #   p ['localise?3', url, @front_matter['toRoot']]
      # end

      return url
    end

    def merge( markdown)
      merged, carry = [], ''

      markdown.flatten.each do |line|
        if /\n$/ =~ line
          merged << carry + line
          carry = ''
        else
          carry += line
        end
      end

      (carry != '') ? merged + [carry] : merged
    end

    def method_missing( verb, *args)
      error( verb.to_s + ": ???")
    end

    def newline( markdown)
      markdown + ["\n"]
    end

    def nestable?( markdown)
      markdown.each do |line|
        return false if /^<\w/ =~ line
      end
      true
    end

    def output_path( url, article)
      if article.root
        return @output_dir + '/content/_index.md'
      end

      stem = @output_dir + '/content/' + article.relative_url.sub( /\.[a-z]*$/i, '').sub( '/index', '/_index')
      disambiguate_path( stem, article) + '.md'
    end

    def paragraph( md)
      ["\n"] + strip( md) + ["\n", "\n"]
    end

    def raw( html)
      html = html.gsub( /href\s*=\s*"[^"]*"/) do |ref|
        ref1 = localise(ref.split('"')[1])
        "href=\"#{ref1}\""
      end

      html = html.gsub( /src\s*=\s*"[^"]*"/) do |ref|
        ref1 = localise(ref.split('"')[1])
        "src=\"#{ref1}\""
      end

      ["\n", html, "\n"]
    end

    def raw?( markdown)
      markdown.each do |line|
        return true if /^<\w/i =~ line
      end
      false
    end

    def register_article( url, article)
      article.tags.each_pair do |section, tag|
        @tag2internal[section + ':' + tag]
      end
    end

    def restore_generation
      @article_url, @article_error, @path, @front_matter = * @saved.pop
    end

    def save_generation
      @saved << [@article_url, @article_error, @path, @front_matter]
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

    def strip( markdown)
      while (! markdown.empty?) && (markdown[0] == "\n")
        markdown = markdown[1..-1]
      end

      while (! markdown.empty?) && (markdown[-1] == "\n")
        markdown = markdown[0..-2]
      end

      if ! markdown.empty?
        markdown[0] = markdown[0].lstrip
        markdown[-1] = markdown[-1].rstrip
      end

      markdown
    end

    def style( styles, md)
      styling = ''
      styles.each do |style|
        if style == :bold
          styling = '**'
        elsif style == :big
        elsif style == :cite
          styling = '**'
        elsif style == :code
        elsif style == :emphasized
          styling = '*'
        elsif style == :italic
          styling = '*'
        elsif style == :inserted
        elsif style == :keyboard
        elsif style == :small
        elsif style == :strike
        elsif style == :superscript
        elsif style == :teletype
        elsif style == :underline
          styling = '*'
        elsif style == :variable
          styling = '*'
        else
          error( "style_begin: #{styles.collect {|s| s.to_s}.join( ' ')}")
        end
      end

      [styling] + md + [styling]
    end

    def table( rows)
      ["\n"] + [table_row( rows[0]), table_separator( rows[0])] +
      rows[1..-1].collect {|row| table_row( row)} +
      ["\n"]
    end

    def table_separator( row)
      '|' + row.collect{'-|'}.join('')
    end

    def table_row( row)
      '|' + row.collect {|cell| cell.gsub( '|', '\\|')}.join('|') + "|\n"
    end

    def text( str)
      [str.gsub( "\n", ' ')]
    end

    def textual?( markdown)
      return true if markdown.size == 0
      return false if markdown.size > 1
      return false if /^[<]/ =~ markdown[0]
      return false if /\n$/ =~ markdown[0]
      true
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
module Generators
  class Hugo

    # Adorned text stanza
    class AdornedStanza
      def initialize( text)
        @text = text
      end

      def adorn( prefix)
        AdornedStanza.new( prefix + @text)
      end

      def empty?
        false
      end

      def include?( str)
        @text.include?( str)
      end

      def merge( other)
        nil
      end

      def output
        @text
      end
    end

    # Basic text stanza
    class Stanza
      attr_reader :text

      def initialize( text)
        @text = text.gsub( /[\s\n]/, ' ').gsub( '\\', '\\\\')
      end

      def adorn( prefix)
        AdornedStanza.new( prefix + output)
      end

      def empty?
        @text.strip == ''
      end

      def include?( str)
        @text.include?( str)
      end

      def merge( other)
        other.is_a?(Stanza) ? Stanza.new( @text + other.text) : nil
      end

      def output
        t = @text.strip
        (/^[:\-#=>\d`\|]/ =~ t) ? ('\\' + t) : t
      end

      def style( styling)
        Stanza.new( styling + @text + styling)
      end
    end

    # Raw stanza
    class RawStanza
      def initialize( text)
        @text = text
      end

      def empty?
        false
      end

      def include?( str)
        @text.include?( str)
      end

      def merge( other)
        nil
      end

      def output
        @text
      end
    end

    # Newline stanza
    class NewlineStanza
      def adorn( prefix)
        AdornedStanza.new( prefix)
      end

      def empty?
        true
      end

      def include?( str)
        false
      end

      def merge( other)
        other.is_a?(NewlineStanza) ? self : nil
      end

      def output
        ''
      end
    end

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

      # Redirects
      @redirects = {}

      # Articles organised by index and URL and menu
      @index2articles  = Hash.new {|h,k| h[k] = {}}
      @url2articles    = {}
      @menu            = [[], {}]
    end

    def article( cached, url, article)
      @article_url   = url
      @article_error = false

      if article.root
        path = @output_dir + '/content/_index.md'
      else
        path = @output_dir + '/content' + output_path(url).sub(/.html$/, '.md')
      end
      front_matter  = {'layout'   => (article.mode == :post) ? 'post' : 'article',
                       'mode'     => article.mode.to_s,
                       'origin'   => url,
                       'cache'    => cached,
                       'section'  => article.index.join('-'),
                       'sections' => slug(article.index.join('-'))}
      comment       = []

      article_layout( article, front_matter)
      front_matter['date']  = article.date.strftime( '%Y-%m-%d') if article.date
      front_matter['title'] = article.title if article.title
      text = article.description
      if text && (text != '')
        front_matter['description'] = (text.size < 30) ? text : text[0..28].gsub( / [^ ]+$/, ' ...')
      end
      markdown = article.generate( self)

      write_file( path, "#{front_matter.to_yaml}\n---\n#{strip(markdown).collect {|m| m.output}.join("\n")}")
      comment = []
      comment << 'Raw' if raw?( markdown)
      comment << 'Root' if root_url?( markdown)
      return path, comment.join(' ')
    end

    def article_layout( article, front_matter)
      if article.mode == :home
        front_matter['layout'] = 'home'
        generate_posts_page

        sections = @index2articles.keys.sort
        front_matter['sectionIndex'] = sections.collect do |section|
          {'name' => section, 'key' => slug( section)}
        end

        sections.each do |section|
          generate_section_page( section)
        end
      else
        front_matter['parents'] = [{'url' => '/index.html', 'title' => 'Home'}]
        section = front_matter['section']

        if (front_matter['mode'] == 'article') || (front_matter['mode'] == 'post')
          front_matter['parents'] << {'url'   => '/section-' + slug(section) + '/index.html',
                                      'title' => section}
        end

        if front_matter['mode'] == 'post'
          front_matter['parents'] << {'url'   => '/section-' + slug(section) + '-posts/index.html',
                                      'title' => 'Posts'}
        end
      end
    end

    def asset_copy( cached, url)
      path = @output_dir + '/content/' + url[(@config['root_url'].size)..-1].downcase
      @generated[path] = true
      # if /2005\/thameshotel/ =~ path
      #   p ['asset_copy1', cached, url, path]
      # end
      unless File.exist?( path)
        create_dir( File.dirname( path))
        unless system( "cp #{cached} #{path}")
          raise "Error copying  #{cached} to #{path}"
        end
      end
    end

    def blockquote( md)
      strip(md).collect {|line| line.adorn( '< ')}
    end

    def clean_old_files
      clean_old_files1( @output_dir + '/content')
      ensure_index_md( @output_dir + '/content')
    end

    def clean_old_files1( dir)
      empty = true

      Dir.entries( dir).each do |f|
        next if /^\./ =~ f
        path = dir +'/' + f
        raise "Bad path #{path}" if /[ \?\*]/ =~ path

        if File.directory?( path)
          if clean_old_files1( path)
            # @generated.each_pair do |k,v|
            #   p ['clean_old_files', k, v] if /66-qualifiers/ =~ k
            # end
            puts "... Cleaning #{path}"
            #raise 'Dev'
            #File.delete( path)
            unless system( "rm -r #{path}")
              raise "Error removing #{path}"
            end
          else
            empty = false
          end
        elsif @generated[path]
          empty = false
        else
          puts "... Cleaning #{path}"
          File.delete( path)
          # unless system( "rm -r #{path}")
          #   raise "Error removing #{path}"
          # end
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
      newline + list.collect do |entry|
        entry[0] +
        entry[1..-1].collect {|md| md.collect {|stanza| stanza.adorn( ': ')}} +
        newline
      end.flatten + newline
    end

    def e( name)
      encoded = name.gsub( /\W/, '_')
      @enc2names[encoded] = name
      encoded
    end

    def ensure_index_md( dir)
      unless File.exist?( dir + '/index.md') || File.exist?( dir + '/_index.md')
        write_file( dir + '/_index.md', "---\nlayout: default\ntitle: Dummy\n---\n")
      end

      Dir.entries( dir) do |f|
        next if /^\./ =~ f
        path = dir + '/' + f
        ensure_index_md( path) if File.directory?( path)
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
      path          = @output_dir + '/content/index-posts/_index.md'
      parents       = [{'url'    => '/index.html', 'title' => 'Home'}]
      front_matter  = {'layout'  => 'home_posts',
                       'toRoot'  => '../',
                       'title'   => 'All posts',
                       'parents' => parents}
      write_file( path, "#{front_matter.to_yaml}\n---\n")
    end

    def generate_section_page( section)
      path          = @output_dir + '/content/section-' + slug(section) + '.md'
      parents       = [{'url'     => '/index.html',
                        'title'   => 'Home'}]
      front_matter  = {'layout'   => 'section',
                       'title'    => section,
                       'parents'  => parents,
                       'section'  => section,
                       'sections' => slug(section)}
      write_file( path, "#{front_matter.to_yaml}\n---\n")
      generate_section_posts_page( section)
    end

    def generate_section_posts_page( section)
      path          = @output_dir + '/content/section-' + slug(section) + '-posts/_index.md'
      parents       = [{'url'     => '/index.html',
                         'title'   => 'Home'},
                        {'url'     => '/section-' + slug(section) + '/index.html',
                         'title'   => section}]
      front_matter  = {'layout'   => 'section_posts',
                       'section'  => section,
                       'sections' => slug(section),
                       'title'    => 'All posts for ' + section,
                       'parents'  => parents}
      write_file( path, "#{front_matter.to_yaml}\n---\n")
    end

    def heading( level, markdown)
      strip(markdown).collect {|m| m.adorn( '######'[0...level] + ' ')}
    end

    def hr
      [AdornedStanza.new( '---')]
    end

    def image( src, title)
      [Stanza.new("![#{title}](#{localise(src)})")]
    end

    def link( text, href)
      return [] if text.empty? || text[0].empty?
      [Stanza.new("[#{text[0].text}](#{localise href})")]
    end

    def list( type, items)
      items = items.collect do |item|
        merge(item)
        #item.select {|line| line && (! line.empty?)} #.collect {|line| line.rstrip}
      end

      items = items.select {|item| ! item.empty?}

      if type == :ordered
        out = []
        items.each_index do |i|
          item = items[i]
          indent = "          "[0...((i+1).to_s.size+2)]
          out << [item[0].adorn( "#{i+1}. ")] +
                  item[1..-1].collect {|line| line.adorn(indent)}
        end
        out.flatten
      else
        items.collect do |item|
          [item[0].adorn( '- ')] + item[1..-1].collect {|line| line.adorn( '  ')}
        end.flatten
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

      # Redirected?
      limit = 100
      while @redirects[url] && (limit > 0)
        url = @redirects[url]
        limit -= 1
      end

      raise "Too many redirects for #{url0}" if limit == 0
      output_path( url)
    end

    def menu_depth( menu)
      depth = 0
      menu[1].each_value do |menu1|
        d = menu_depth( menu1) + 1
        depth = d if d > depth
      end
      depth
    end

    def menu_generate( keys, menu, list)
      if ! keys.empty?
        list << {
            'identifier' => keys.collect {|key| slug(key)}.join('-'),
            'name'       => keys[-1],
            'url'        => 'index.html',
            'parent'     => (keys.size > 1) ? keys[0...-1].collect {|key| slug(key)}.join('-') : nil
                }
      end

      menu[1].each_pair do |key, menu1|
        menu_generate( keys + [key], menu1, list)
      end
    end

    def menu_print( keys, menu, depth, io)
      (0...depth).each do |i|
        io.print "#{(i < keys.size) ? keys[i] : ''}\t"
      end

      articles, posts = 0, 0
      menu[0].each do |article|
        if article.mode == :article
          articles += 1
        else
          posts += 1
        end
      end

      io.puts "#{(articles > 0) ? articles.to_s : ''}\t#{(posts > 0) ? posts.to_s : ''}"

      menu[1].keys.sort.each do |key|
        menu_print( keys + [key], menu[1][key], depth, io)
      end
    end

    def merge(markdown)
      merged = []

      markdown.flatten.each do |item|
        if item.is_a?( TrueClass)
          p [markdown, merged, item]
        end
        if merged[0] && (m = merged[-1].merge(item))
          if m.is_a?( TrueClass)
            p [markdown, merged, item]
          end
          merged[-1] = m
        else
          merged << item
        end
      end

      merged
    end

    def method_missing( verb, *args)
      error( verb.to_s + ": ???")
    end

    def newline( markdown=[])
      [NewlineStanza.new()] + markdown
    end

    def nestable?( markdown)
      markdown.each do |line|
        return false if line.is_a?( RawStanza)
      end
      true
    end

    def output_path( url)
      url = url.split('#')[0].sub( /^http:/, 'https:')
      if article = @url2articles[url]
        return '/index.html' if article.root
        section = article.index.join('-')

        '/' +
        article.index.collect {|i| slug(i)}.join('/') +
        "/#{@index2articles[section][article.url]}-#{slug(article.title)}" +
        '/index.html'

      elsif m = %r{^[^/]*//[^/]*(/.*)$}.match( url)
        m[1]
      else
        raise "output_trail: #{url}"
      end
    end

    def paragraph( md)
      newline + strip(md) + newline
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

      [RawStanza.new( html)]
    end

    def raw?( markdown)
      markdown.each do |line|
        return true if line.is_a?( RawStanza)
      end
      false
    end

    def redirect( from, to)
      @redirects[from] = to
    end

    def register_article( url, article)
      #url = url.sub( /^http:/, 'https:')
      @url2articles[url] = article
      section = article.index.join('-')
      @index2articles[section][url] = (1 + @index2articles[section].size)

      menu, index = @menu, article.index
      while ! index.empty?
        menu[1][index[0]] = [[], {}] unless menu[1][index[0]]
        menu  = menu[1][index[0]]
        index = index[1..-1]
      end

      menu[0] << article
    end

    def root_url?( markdown)
      markdown.each do |line|
        return true if line.include?( @config['root_url'])
      end
      false
    end

    def site_begin
      unless system( "rsync -r --delete #{@config_dir}/layouts/ #{@output_dir}/layouts/")
        raise "Error copying layouts"
      end
      copy_template( 'index.css', 'content/index.css')
    end

    def site_end
      site_config = @config['hugo']['config']
      site_config['menu'] = {'main' => []}
      menu_generate( [], @menu, site_config['menu']['main'])
      write_file( @output_dir + '/config.yaml', site_config.to_yaml)
      toml = @output_dir + '/config.toml'
      File.delete( toml) if File.exist?( toml)

      depth = menu_depth( @menu)
      File.open( @config_dir + '/menu.tsv', 'w') do |io|
        (0...depth).each do |i|
          io.print "Menu #{i+1}\t"
        end
        io.puts "Articles\tPosts"

        menu_print( [], @menu, depth, io)
      end
    end

    def slug( text)
      text.gsub( /[^a-z0-9]/i, '_').downcase
    end

    def strip( markdown)
      markdown = merge(markdown)

      while (! markdown.empty?) && markdown[0].is_a?( NewlineStanza)
        markdown = markdown[1..-1]
      end

      while (! markdown.empty?) && markdown[-1].is_a?( NewlineStanza)
        markdown = markdown[0..-2]
      end

      markdown
    end

    def style( styles, md)
      raise 'Unable to style' if md.size > 1
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
        elsif style == :subscript
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

      md.collect {|line| line.style( styling)}
    end

    def table( rows)
      newline + [table_row( rows[0]), table_separator( rows[0])] +
      rows[1..-1].collect {|row| table_row( row)} +
      newline
    end

    def table_separator( row)
      AdornedStanza.new( '|' + row.collect{'-|'}.join(''))
    end

    def table_row( row)
      AdornedStanza.new( '|' + row.collect {|cell| cell.gsub( '|', '\\|')}.join('|') + "|")
    end

    def text( str)
      [Stanza.new( str)]
    end

    def textual?( markdown)
      return true if markdown.size == 0
      return false if markdown.size > 1
      markdown[0].is_a?( Stanza)
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
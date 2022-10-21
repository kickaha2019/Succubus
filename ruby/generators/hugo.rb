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
        (/^[:\-#=>`\|]/ =~ t) ? ('\\' + t) : t
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

    def initialize( config_dir, config)
      @config_dir    = config_dir
      @config        = config
      @generation    = {}
      @written       = {}
      @taxonomies    = {}
      @article_error = false
      @any_errors    = false
      @article_url   = nil
      @path2article  = {}
      @enc2names     = {}
      @output_dir    = config['output_dir']

      # Menu structure
      @menu          = [[], {}]
    end

    def article( url, article, output)
      @article_url   = url
      @article_error = false

      front_matter  = {'layout'   => (article.mode == :post) ? 'post' : 'article',
                       'mode'     => article.mode.to_s,
                       'origin'   => url,
                       'section'  => slug(article.index)}
      comment       = []

      article.index.each_index do |i|
        front_matter["index#{i}"] = slug(article.index[0..i])
      end

      article_layout( article, front_matter)
      front_matter['date']  = article.date.strftime( '%Y-%m-%d') if article.date
      front_matter['title'] = article.title if article.title
      text = article.description
      if text && (text != '')
        front_matter['description'] = (text.size < 30) ? text : text[0..28].gsub( / [^ ]+$/, ' ...')
      end

      markdown = article.generate( self)
      front_matter['raw'] = true if raw?( markdown)

      write_file( @output_dir + '/content' + output,
                  "#{front_matter.to_yaml}\n---\n#{strip(markdown).collect {|m| m.output}.join("\n")}")
      @article_error
    end

    def article_layout( article, front_matter)
      if article.mode == :home
        front_matter['layout'] = 'home'
      end
    end

    def blockquote( md)
      strip(md).collect {|line| line.adorn( '< ')}
    end

    def clean_old_files( dir)
      empty = true

      Dir.entries( dir).each do |f|
        next if /^\./ =~ f
        path = dir +'/' + f
        raise "Bad path #{path}" if /[ \?\*]/ =~ path

        if File.directory?( path)
          if clean_old_files( path)
            puts "... Cleaning #{path}"
            unless system( "rm -r #{path}")
              raise "Error removing #{path}"
            end
          else
            empty = false
          end
        elsif @written[path]
          empty = false
        else
          puts "... Cleaning #{path}"
          File.delete( path)
        end
      end

      empty
    end

    def copy_asset( source, url)
      relpath = url[(@config['root_url'].size-1)..-1].downcase
      path = @output_dir + '/content' + relpath

      unless File.exist?( path)
        create_dir( File.dirname( path))
        unless system( "cp #{source} #{path}")
          raise "Error copying  #{source} to #{path}"
        end
      end

      relpath
    end

    def copy_template( template_path, dest_path)
      data = IO.read( @config_dir + '/' + template_path)
      path = @output_dir + '/content/' + dest_path
      write_file( path, data)
      @written[path] = true
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
      @written[dir + '/_index.md'] = true
      unless File.exist?( dir + '/index.md') || File.exist?( dir + '/_index.md')
        write_file( dir + '/_index.md', "---\nlayout: default\ntitle: Dummy\n---\n")
      end

      Dir.entries( dir).each do |f|
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
      path           = @output_dir + '/content/index-posts/_index.md'
      create_dir( File.dirname( path))
      @written[path] = true
      parents        = [{'url'    => '/index.html', 'title' => 'Home'}]
      front_matter   = {'layout'  => 'home_posts',
                        'toRoot'  => '../',
                        'title'   => 'All posts',
                        'parents' => parents}
      write_file( path, "#{front_matter.to_yaml}\n---\n")
    end

    def generate_section_page( keys)
      path           = @output_dir + '/content/sections/' + slug(keys) + '/_index.md'
      create_dir( File.dirname( path))
      @written[path] = true
      parents        = [{'url'     => '/index.html',
                         'title'   => 'Home'}]

      front_matter   = {'layout'   => 'section',
                        'title'    => keys.join( ' / '),
                        'parents'  => parents,
                        'section'  => slug(keys)}

      keys.each_index do |i|
        front_matter["index#{i}"] = slug(keys[0..i])
      end

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
      if loc = localise( href)
        [Stanza.new("[#{text[0].text}](#{loc})")]
      else
        [Stanza.new( "*#{text[0].text}*")]
      end
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

    def localise(url, index=0)
      return url unless @generation[url]
      info = @generation[url]

      if info['redirect']
        url  = info['redirect']
        info = @generation[url]
      end

      output = info ? info['output'] : nil

      if output.is_a?( Array)
        output = output[index]
      end

      output ? output.gsub( /_index\.md$/, 'index.md').gsub( /\.md$/, '.html') : nil
    end

    def menu_generate( keys, menu, list, depth=0)
      if ! keys.empty?
        generate_section_page( keys)
        ident         = slug( keys)

        if menu[0].empty?
          url = ''
        elsif menu[0].size == 1
          url = localise( menu[0][0].url, menu[0][0].order)
        else
          url = "/sections/#{ident}/index.html"
        end

        list << {
            'identifier' => ident,
            'name'       => keys[-1],
            'url'        => url,
            'parent'     => (keys.size > 1) ? slug(keys[0...-1]) : nil
                }
      end

      menu[1].each_pair do |key, menu1|
        menu_generate( keys + [key], menu1, list, depth+1)
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
            p ['merge', markdown, merged, item]
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

    def output_path( url, article, unique)
      url = url.split('#')[0].sub( /^http:/, 'https:')
      return '/_index.md' if article.root?

      if article.index.empty?
        section = 'none'
      else
        section = slug(article.index, '/')
      end

      title = slug(article.title)
      if title == ''
        title = 'none'
      end

      path = '/' +
             section +
             "/#{title}#{unique}" +
             '/index.md'

      create_dir( File.dirname( @output_dir + '/content' + path))

      path
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

    def record_generation( generation)
      @generation = generation
      @written    = {}

      @generation.each_value do |info|
        if output = info['output']
          if output.is_a?( Array)
            output.each do |out|
              @written[ @output_dir + '/content' + out] = true
            end
          else
            @written[ @output_dir + '/content' + output] = true
          end
        end
      end
    end

    def register_article( article)
      section = slug(article.index)

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

    def site
      unless system( "rsync -r --delete #{@config_dir}/layouts/ #{@output_dir}/layouts/")
        raise "Error copying layouts from #{@config_dir}/layouts/ to #{@output_dir}/layouts/"
      end

      site_config = @config['hugo']['config']
      site_config['menu'] = {'main' => []}
      menu_generate( [], @menu, site_config['menu']['main'])
      write_file( @output_dir + '/config.yaml', site_config.to_yaml)
      toml = @output_dir + '/config.toml'
      File.delete( toml) if File.exist?( toml)

      generate_posts_page
      ensure_index_md( @output_dir + '/content')
      copy_template( 'index.css','index.css')
      clean_old_files( "#{@output_dir}/content")
    end

    def slug( text, separ = '-')
      if text.is_a?( Array)
        text.collect {|t| slug(t)}.join( separ)
      else
        text.gsub( /[^a-z0-9]/i, '_').downcase
      end
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
      AdornedStanza.new( '|' + row.collect {|cell| merge(cell)[0].output.gsub( '|', '\\|')}.join('|') + "|")
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
      unless File.exist?( path) && (IO.read( path) == data)
#        p ['write_file2', path, File.exist?( path), IO.read( path), data]
        puts "... Writing #{path}"
        File.open( path, 'w') {|io| io.print data}
      end
    end
  end
end
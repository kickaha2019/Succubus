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
            puts "... Would delete #{path}"
#            File.delete( path)
          else
            empty = false
          end
        elsif @generated[path]
          empty = false
        else
          puts "... Would delete #{path}"
#          File.delete( path)
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

    def image( src)
      newline
      @markdown << "![](#{src})\n"
    end

    def link_begin( href)
      @markdown << "["
    end

    def link_end( href)
      @markdown << "](#{href}"
    end

    def method_missing( verb, *args)
      error( verb.to_s + ": ???")
    end

    def newline
      @markdown << "\n" unless @markdown[-1] && @markdown[-1][-1] == "\n"
    end

    def paragraph_begin
      @markdown << "\n\n" unless @markdown[-1] == "\n\n"
    end

    def paragraph_end
      paragraph_begin
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
      return if styles.empty?
      error( "style_begin: #{styles.collect {|s| s.to_s}.join( ' ')}")
    end

    def style_end( styles)
      return if styles.empty?
      error( "style_end: #{styles.collect {|s| s.to_s}.join( ' ')}")
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
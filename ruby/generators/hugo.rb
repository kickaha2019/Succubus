module Generators
  class Hugo
    def initialize( config, output_dir)
      @config     = config
      @output_dir = output_dir
      @taxonomies = {}
      @written    = {}
      @generated  = {}
    end

    def article_begin( url)
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
      write_file( @path, "---\n#{@front_matter.to_yaml}\n---\n#{@markdown.join("\n")}")
    end

    def article_title( title)
      @front_matter['title'] = title
    end

    def clean_old_files( dir=nil)
      dir   = @output_dir + '/content' unless dir
      empty = true

      Dir.entries( dir).each do |f|
        next if /^\./ =~ f
        path = dir +'/' + f

        if File.directory?( path)
          if clean_old_files( path)
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

    def write_file( path, data)
      @generated[path] = true
      create_dir( File.dirname( path))
      unless File.exist?( path) && (IO.read( path).strip == data.strip)
        File.open( path, 'w') {|io| io.print data}
      end
    end
  end
end
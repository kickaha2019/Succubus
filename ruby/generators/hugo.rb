module Generators
  class Hugo
    def initialize( config, output_dir)
      @config     = config
      @output_dir = output_dir
      @taxonomies = {}
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
      unless File.exist?( path) && (IO.read( path).strip == data.strip)
        File.open( path, 'w') {|io| io.print data}
      end
    end
  end
end
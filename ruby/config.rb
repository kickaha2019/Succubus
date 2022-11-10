#
# Wrap configuration settings
#

require 'yaml'

require_relative 'site'

class Config
  def initialize( config_dir)
    @config = YAML.load( IO.read( config_dir + '/config.yaml'))
    @dir    = config_dir

    Dir.entries( config_dir).each do |f|
      if /\.rb$/ =~ f
        require( config_dir + '/' + f)
      end
    end

    @site      = Kernel.const_get( @config['class']).new( self)
    require_relative( 'generators/' + @config['generator'])
    @generator = Kernel.const_get( 'Generators::' + @config['generator']).new( self, @site)
  end

  def debug_url?( url)
    url == @config['debug_url']
  end

  def dir
    @dir
  end

  def generator
    @generator
  end

  def hugo_config
    @config['hugo']['config']
  end

  def include_urls
    if @config['include_urls']
      @config['include_urls'].each {|url| yield url}
    end
  end

  def in_site( url)
    root_url == url[0...(root_url.size)]
  end

  def leech_assets?
    @config['leech_assets']
  end

  def login_redirect?( url)
    lru = @config['login_redirect_url']
    return false if lru.nil?
    (lru + '?') == url[0..(lru.size)]
  end

  def n_workers
    @config['workers']
  end

  def output_dir
    @config['output_dir']
  end

  def root_url
    @config['root_url']
  end

  def site
    @site
  end

  def temp_dir
    @config['temp_dir']
  end
end

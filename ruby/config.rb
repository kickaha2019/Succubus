#
# Wrap configuration settings
#

require 'yaml'

class Config
  def initialize( config)
    @config = YAML.load( IO.read( config))
  end

  def debug_url?( url)
    url == @config['debug_url']
  end

  def get_site( site_file)

  end

  def include_urls
    if @config['include_urls']
      @config['include_urls'].each {|url| yield url}
    end
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
end

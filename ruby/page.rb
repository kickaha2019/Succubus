class Page
  attr_reader :url, :document, :tags
  attr_accessor :date, :mode, :title

  def initialize( site, root_url, taxonomy, url, document)
    @site     = site
    @root_url = root_url
    @taxonomy = taxonomy
    @url      = url
    @document = document
    @title    = nil
    @date     = nil
    @tags     = []
    @mode     = nil
  end

  def absolutise( url)
    @site.absolutise( @url, url)
  end

  def add_tag( species, name)
    raise "Unknown taxonomy #{species}" unless @taxonomy[species]
    @tags << [species, name]
  end

  def css( expr)
    @document.css( expr)
  end

  def relative_path
    @url[@root_url.size..-1].split('/')
  end
end
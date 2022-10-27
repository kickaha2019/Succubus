class Page
  attr_reader :url, :document, :index, :root_url
  attr_accessor :date, :mode, :title, :description

  def initialize( site, root_url, taxonomy, url, document)
    @site        = site
    @root_url    = root_url
    @taxonomy    = taxonomy
    @url         = url
    @document    = document
    @description = nil
    @title       = nil
    @date        = nil
    @index       = []
    @mode        = nil
  end

  def absolutise(url)
    @site.absolutise(@url, url)
  end

  def index=( names)
    raise 'Index too deep' if names.size > 2
    @index = names
  end

  def css( expr)
    @document.css( expr)
#    Nodes.new( @document.css( expr))
  end

  def relative_path
    @url[@root_url.size..-1].split('/')
  end

  def relative_url
    @url[@root_url.size..-1]
  end

  def root?
    @url == @root_url
  end
end
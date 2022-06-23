class Page
  attr_reader :url, :document, :tags
  attr_accessor :date, :mode, :title

  def initialize( root_url, taxonomy, url, document)
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
    dir_url = @url

    if /\/$/ =~ dir_url
      dir_url = dir_url[0..-2]
    else
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    while /^\.\.\// =~ url
      url     = url[3..-1]
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    if /^\// =~ url
      return @root_url + url[1..-1]
    end

    if /^\w*:/ =~ url
      url
    else
      dir_url + '/' + url
    end
  end

  def add_tag( species, name)
    raise "Unknown taxonomy #{species}" unless @taxonomy[species]
    @tags << [species, name]
  end

  def css( expr)
    @document.css( expr)
  end
end
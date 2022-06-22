class Page
  attr_reader :url, :document, :title, :tags

  def initialise( taxonomy, url, document)
    @taxonomy = taxonomy
    @url      = url
    @document = document
    @title    = nil
    @tags     = []
  end

  def add_tag( species, name)
    raise "Unknown taxonomy #{species}" unless @taxonomy[species]
    @tags << [species, name]
  end

  def class_text( clazz)
    @document.css( '.' + clazz).text.strip
  end

  def title=( text)
    @title = text
  end
end
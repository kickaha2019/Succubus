class Place
  attr_reader :element, :children, :page

  def initialize( page, element, children)
    @page     = page
    @element  = element
    @children = children
  end

  def [](name)
    @element[name]
  end

  def absolutise( url)
    @page.absolutise(url)
  end

  def content?
    @children.inject( false) {|flag, child| flag | child.content?}
  end

  def date
    @page.date
  end

  def debug?
    @element['debug']
  end

  def description
    @page.description
  end

  def find_children( clazz)
    @children.select {|child| child.is_a?( clazz)}
  end

  def index
    @page.index
  end

  def name
    @element.name
  end

  def text
    #@children.inject( @element.text) {|text, child| text + ' ' + child.text}
    @element.text
  end

  def title
    @page.title
  end

  def url
    @page.url
  end
end
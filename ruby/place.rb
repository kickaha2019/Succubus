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
    @page.absolutise( url)
  end

  def content?
    @children.inject( false) {|flag, child| flag | child.content?}
  end

  def name
    @element.name
  end

  def tags
    @page.tags
  end

  def text
    @children.inject( @element.text) {|text, child| text + ' ' + child.text}
  end

  def title
    @page.title
  end
end
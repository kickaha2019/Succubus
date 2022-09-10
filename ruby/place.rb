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

  def date
    @page.date
  end

  def debug?
    @element['debug']
  end

  def debug_report( element)
    if debug?
      contents = []
      if element.is_a?( Elements::Unknown)
        puts "... #{@element['debug']}: #{element.class.to_s} initialisation"
        contents = element.contents
      else
        puts "... #{@element['debug']}: Array initialisation"
        contents = element
      end
      contents.each do |child|
        puts "...  #{child.class.to_s}: #{child.text[0..29].gsub( /\s/, ' ').strip}"
      end
      puts "\n"
    end
  end

  def description
    @page.description
  end

  def find_children( clazz)
    @children.select {|child| child.is_a?( clazz)}
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

  def url
    @page.url
  end
end
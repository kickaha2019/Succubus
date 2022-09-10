module Elements
  class Unknown
    attr_reader :index, :contents, :element
    @@next_index = 0

    def initialize( place)
      @@next_index += 1
      @index       = @@next_index
      @contents    = place.children
      @element     = place.element
      @debug       = @element['debug']
      place.debug_report( self)
    end

    def article?
      false
    end

    def children
      @contents.each {|child| yield child}
    end

    def contains_article?
      return true if article?
      children do |child|
        return true if child.article?
      end
      false
    end

    def content?
      children do |child|
        return true if child.content?
      end
      false
    end

    def describe
      if @element['class']
        @element.name + ': ' + @element['class']
      else
        @element.name
      end
    end

    def error?
      false
    end

    def find_children( clazz)
      @contents.select {|child| child.is_a?( clazz)}
    end

    def generate( generator)
      generate_children( generator)
    end

    def generate_children( generator)
      generator.merge( @contents.collect do |child|
        child.generate( generator)
      end)
    end

    def grokked?
      false
    end

    def links
      @contents.each do |child|
        child.links {|link| yield link}
      end
    end

    def raw
      @element.to_html
    end

    def self.reset_next_index
      @@next_index = 0
    end

    def text
      t = ''
      children do |child|
        t = t + ' ' + child.text
      end
      t.strip
    end

    def title
      nil
    end

    def tooltip
      "#{self.class.to_s}: "
    end

    def tree
      children do |child|
        child.tree {|el| yield el}
      end
      yield self
    end
  end
end

module Elements
  class Unknown
    attr_reader :index, :contents
    @@next_index = 0

    def initialize( place)
      @@next_index += 1
      @index       = @@next_index
      @contents    = place.children
      @describe    = place.element.name
      if place.element['class']
        @describe += ': ' + place.element['class']
      end
    end

    def article?
      false
    end

    def children
      @contents.each {|child| yield child}
    end

    def children_text?
      children do |child|
        return false unless child.text?
      end
      true
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
      @describe
    end

    def error?
      false
    end

    def find_children( clazz)
      @contents.select {|child| child.is_a?( clazz)}
    end

    def generate( generator)
      @contents.each do |child|
        child.generate( generator)
      end
    end

    def grokked?
      false
    end

    def links
      @contents.each do |child|
        child.links {|link| yield link}
      end
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

    def text?
      false
    end

    def title
      nil
    end

    def tooltip
      nil
    end

    def tree
      children do |child|
        child.tree {|el| yield el}
      end
      yield self
    end
  end
end

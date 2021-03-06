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

    def children_text?
      @contents.each do |child|
        return false unless child.text?
      end
      true
    end

    def contains_article?
      @contents.inject( article?) {|flag, child| flag | child.contains_article?}
    end

    def content?
      @contents.inject( false) {|flag, child| flag | child.content?}
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
      @contents.inject( '') {|text, child| text + ' ' + child.text}
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
      @contents.each do |child|
        child.tree {|el| yield el}
      end
      yield self
    end
  end
end

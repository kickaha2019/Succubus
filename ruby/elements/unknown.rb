module Elements
  class Unknown
    attr_reader :id, :contents, :element
    @@next_id = 0

    def initialize( place)
      @@next_id += 1
      @id       =  @@next_id
      @contents =  place.children
      @element  =  place.element
      @debug    =  @element['debug']
      @advise   = []
    end

    def advise( index, url, title, date)
      @advise << {index:index, url:url, title:title, date:date}
    end

    def advises
      @advise.each do |row|
        yield row
      end
      children do |child|
        child.advises do |row|
          yield row
        end
      end
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

    def debug?
      @debug
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
      generator.merge(@contents.collect do |child|
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

    def self.reset_next_id
      @@next_id = 0
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

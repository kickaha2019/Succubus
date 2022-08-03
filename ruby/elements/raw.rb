require_relative 'group'

module Elements
  class Raw < Unknown
    def initialize( place)
      super
      @html = place.element.to_html
    end

    def children
    end

    def content?
      true
    end

    def describe
      'Raw: ' + super
    end

    def generate( generator)
      generator.raw( @html)
    end

    def grokked?
      true
    end
  end
end



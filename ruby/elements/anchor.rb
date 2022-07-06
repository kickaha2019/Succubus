require_relative 'unknown'

module Elements
  class Anchor < Unknown
    attr_reader :href

    def initialize( place, href)
      super( place)
      @href = href
    end

    def content?
      true
    end

    def describe
      super + ': ' + @href
    end

    def generate( generator, before, after)
      generator.style_begin( before)
      generator.link_begin( @href)
      super( generator, [], [])
      generator.link_end( @href)
      generator.style_end( after)
    end

    def grokked?
      true
    end

    def links
      super {|link| yield link}
      yield @href
    end
  end
end



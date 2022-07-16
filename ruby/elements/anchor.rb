require_relative 'unknown'

module Elements
  class Anchor < Unknown
    attr_reader :href

    def initialize( place, href, title)
      super( place)
      @href  = href
      @title = title
    end

    def content?
      true
    end

    def describe
      super + ': ' + @href
    end

    def generate( generator, before, after)
      if generator.link_text_only?
        t = text
        t = @title if t.strip == ''
        if t.nil? && @contents[0].is_a?( Elements::Image)
          t = @contents[0].title
        end
        generator.style_begin( before)
        generator.link_text( @href, t)
        generator.style_end( after)
      else
        generator.style_begin( before)
        generator.link_begin( @href)
        super( generator, [], [])
        generator.link_end( @href)
        generator.style_end( after)
      end
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



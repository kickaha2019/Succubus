require_relative 'text_group'

module Elements
  class Anchor < TextGroup
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

    def generate( generator)
      t = text
      t = @title if t.strip == ''
      @contents.each do |child|
        t = child.title if t.nil?
      end
      generator.link( t, @href)
    end

    def links
      super {|link| yield link}
      yield @href
    end

    def text?
      true
    end

    def title
      @title
    end
  end
end



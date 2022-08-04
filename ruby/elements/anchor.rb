require_relative 'text_group'

module Elements
  class Anchor < TextGroup
    attr_reader :href

    def initialize( place, href, title)
      super( place)
      @href  = href
      @title = title
    end

    def anchor_text
      t = text
      t = @title if t.strip == ''
      @contents.each do |child|
        t = child.title if t.nil?
      end
      t ? t.strip : @href
    end

    def content?
      true
    end

    def describe
      super + ': ' + @href
    end

    def error?
      unless anchor_text != ''
        return true, 'Non text children'
      end
      false
    end

    def generate( generator)
      generator.link( anchor_text, @href)
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



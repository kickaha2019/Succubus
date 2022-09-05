require_relative 'group'

module Elements
  class Anchor < Group
    attr_reader :href

    def initialize( place, href, title)
      super( place)
      @href  = href.strip
      @title = title
    end

    def anchor_text( generator)
      t = generate_children( generator)
      return false, t unless generator.textual?( t)
      return true, t unless t.empty?

      t = @title
      @contents.each do |child|
        t = child.title if t.nil?
      end
      return true, [t ? t.strip : @href]
    end

    def content?
      true
    end

    def describe
      super + ': ' + @href
    end

    def generate( generator)
      return [] if /^#/ =~ @href
      ok, text = anchor_text( generator)
      if ok
        generator.link( text, @href)
      else
        generator.raw( raw)
      end
    end

    def links
      super {|link| yield link}
      yield @href
    end

    def title
      @title
    end
  end
end



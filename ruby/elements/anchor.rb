require_relative 'group'

module Elements
  class Anchor < Group
    attr_reader :href

    def initialize( place, href, title)
      super( place)
      @href  = href.gsub( /[\s\n]/, '')
      @title = title
    end

    def content?
      true
    end

    def describe
      super + ': ' + @href
    end

    def generate( generator)
      text = generate_children( generator)
      p ['Anchor::generate', @href, text] if debug?
      return [] if text.empty?
      if generator.textual?( text)
        generator.link( text, @href)
      else
        generator.raw( raw)
      end
    end

    def links
      super {|link| yield link}
      yield @href unless /^#/ =~ @href
    end

    def title
      @title
    end
  end
end



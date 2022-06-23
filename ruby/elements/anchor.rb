require_relative 'unknown'

module Elements
  class Anchor < Unknown
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

    def grokked?
      true
    end

    def links
      super {|link| yield link}
      yield @href
    end
  end
end



require_relative 'unknown'

module Elements
  class Image < Unknown
    def initialize( place, path)
      super( place)
      @path = path
    end

    def content?
      true
    end

    def describe
      super + ': ' + @path
    end

    def generate( generator, before, after)
      generator.image( @path)
    end

    def grokked?
      true
    end

    def links
      super {|link| yield link}
      yield @path
    end
  end
end


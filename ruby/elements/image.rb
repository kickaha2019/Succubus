require_relative 'unknown'

module Elements
  class Image < Unknown
    attr_reader :title

    def initialize( place, path, title)
      super( place)
      @path  = path
      @title = title
    end

    def content?
      true
    end

    def describe
      super + ': ' + @path
    end

    def generate( generator)
      generator.image( @path, @title)
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


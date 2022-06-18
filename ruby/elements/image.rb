require_relative 'unknown'

module Elements
  class Image < Unknown
    def initialize( doc, path)
      super( doc, [])
      @path = path
    end

    def content?
      true
    end

    def describe
      @path + ': ' + super
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


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
      @path
    end

    def grokked?
      true
    end
  end
end


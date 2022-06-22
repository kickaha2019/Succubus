require_relative 'unknown'

module Elements
  class Article < Unknown
    def initialize( place)
      super
      @title = nil
    end

    def article?
      true
    end

    def content?
      false
    end

    def grokked?
      false
    end

    def text
      ''
    end

    def tooltip
      @title
    end

    def title( text)
      @title = text
      self
    end
  end
end



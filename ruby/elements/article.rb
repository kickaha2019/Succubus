require_relative 'unknown'

module Elements
  class Article < Unknown
    attr_reader :style

    def initialize( place, style)
      super( place)
      @style = style
    end

    def article?
      true
    end

    # def compile( generator)
    #   generator.article_markdown( generate( generator), @style)
    # end

    def content?
      false
    end

    def error?
      tree do |child|
        return true, 'Article inside article' if child.article? && child != self
      end

      return false, nil
    end

    def grokked?
      false
    end

    def text
      ''
    end
  end
end



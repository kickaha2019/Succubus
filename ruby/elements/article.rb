require_relative 'unknown'

module Elements
  class Article < Unknown
    def initialize( doc, children)
      super( doc, children)
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
  end
end


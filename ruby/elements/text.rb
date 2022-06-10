require_relative 'unknown'

module Elements
  class Text < Unknown
    def initialize( doc, text)
      super( doc, [])
      @text = text
    end

    def content?
      true
    end

    def describe
      @text
    end

    def grokked?
      true
    end
  end
end



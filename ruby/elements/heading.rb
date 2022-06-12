require_relative 'unknown'

module Elements
  class Heading < Unknown
    def initialize( doc, level, children)
      super( doc, children)
      @level = level
    end

    def content?
      true
    end

    def describe
      @level
    end

    def grokked?
      true
    end
  end
end



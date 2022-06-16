require_relative 'unknown'

module Elements
  class Section < Unknown
    def initialize( doc, children)
      super( doc, children)
    end

    def content?
      false
    end

    def grokked?
      true
    end

    def text
      ''
    end
  end
end



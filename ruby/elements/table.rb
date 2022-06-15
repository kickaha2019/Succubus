require_relative 'unknown'

module Elements
  class Table < Unknown
    def initialize( doc, children)
      super( doc, children)
    end

    def content?
      true
    end

    def grokked?
      true
    end
  end
end



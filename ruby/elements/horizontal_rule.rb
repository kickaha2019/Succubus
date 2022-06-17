require_relative 'unknown'

module Elements
  class HorizontalRule < Unknown
    def initialize( doc)
      super( doc, [])
    end

    def grokked?
      true
    end
  end
end



require_relative 'unknown'

module Elements
  class Ignore < Unknown
    def initialize( doc, children)
      super( doc, children)
    end

    def grokked?
      true
    end
  end
end



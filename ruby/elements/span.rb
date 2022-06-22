require_relative 'unknown'

module Elements
  class Span < Unknown
    def initialize( place)
      super
    end

    def grokked?
      true
    end
  end
end



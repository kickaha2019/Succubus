require_relative 'unknown'

module Elements
  class Description < Unknown
    def initialize( place)
      super( place)
    end

    def content?
      true
    end

    def grokked?
      true
    end
  end
end



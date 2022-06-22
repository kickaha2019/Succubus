require_relative 'unknown'

module Elements
  class HorizontalRule < Unknown
    def initialize( place)
      super
    end

    def grokked?
      true
    end
  end
end



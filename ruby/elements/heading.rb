require_relative 'unknown'

module Elements
  class Heading < Unknown
    def initialize( place, level)
      super( place)
      @level = level
    end

    def content?
      true
    end

    def describe
      super + ': ' + @level.to_s
    end

    def grokked?
      true
    end
  end
end



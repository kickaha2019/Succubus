require_relative 'unknown'

module Elements
  class Paragraph < Unknown
    def initialize( place)
      super
    end

    def grokked?
      true
    end
  end
end



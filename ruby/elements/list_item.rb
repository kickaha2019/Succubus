require_relative 'unknown'

module Elements
  class ListItem < Unknown
    def initialize( place)
      super
    end

    def content?
      true
    end

    def grokked?
      true
    end
  end
end



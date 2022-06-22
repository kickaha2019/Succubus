require_relative 'unknown'

module Elements
  class Ignore < Unknown
    def initialize( place)
      super
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



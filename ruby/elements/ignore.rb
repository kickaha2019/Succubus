require_relative 'unknown'

module Elements
  class Ignore < Unknown
    def initialize( place)
      super
    end

    def content?
      false
    end

    def generate( generator, before, after)
    end

    def grokked?
      true
    end

    def text
      ''
    end

    def tree
      yield self
    end
  end
end



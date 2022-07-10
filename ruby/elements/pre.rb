require_relative 'unknown'

module Elements
  class Pre < Unknown
    def initialize( place)
      super
    end

    def generate( generator, before, after)
      generator.preformatted( text)
    end

    def grokked?
      true
    end
  end
end



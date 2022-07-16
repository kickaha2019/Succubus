require_relative 'unknown'

module Elements
  class Blockquote < Unknown
    def initialize( place)
      super
    end

    def generate( generator, before, after)
      generator.blockquote_begin
      super( generator, [], [])
      generator.blockquote_end
    end

    def grokked?
      true
    end
  end
end



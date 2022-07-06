require_relative 'unknown'

module Elements
  class Paragraph < Unknown
    def initialize( place)
      super
    end

    def generate( generator, before, after)
      generator.paragraph_begin
      super
      generator.paragraph_end
    end

    def grokked?
      true
    end
  end
end



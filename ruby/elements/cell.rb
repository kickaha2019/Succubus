require_relative 'unknown'

module Elements
  class Cell < Unknown
    def initialize( place)
      super
      @styling = (place.name == 'TH') ? [:bold, :centre] : [:left]
    end

    def content?
      true
    end

    def generate( generator, before, after)
      generator.cell_begin
      super
      generator.cell_end
    end

    def grokked?
      true
    end
  end
end

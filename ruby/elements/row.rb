require_relative 'unknown'

module Elements
  class Row < Unknown
    def initialize( place)
      super
    end

    def content?
      true
    end

    def generate( generator, before, after)
      generator.row_begin
      super
      generator.row_end
    end

    def grokked?
      true
    end
  end
end



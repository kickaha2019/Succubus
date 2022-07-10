require_relative 'unknown'

module Elements
  class Break < Unknown
    def initialize( place)
      super
    end

    def generate( generator, before, after)
      generator.break_begin
      super
      generator.break_end
    end

    def grokked?
      true
    end
  end
end



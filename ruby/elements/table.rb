require_relative 'unknown'

module Elements
  class Table < Unknown
    def initialize( place)
      super
    end

    def content?
      true
    end

    def generate( generator, before, after)
      generator.table_begin
      super
      generator.table_end
    end

    def grokked?
      true
    end
  end
end



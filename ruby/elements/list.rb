require_relative 'unknown'

module Elements
  class List < Unknown
    def initialize( place, type)
      super( place)
      @type = type
    end

    def content?
      true
    end

    def describe
      super + ': ' + @type.to_s
    end

    def generate( generator, before, after)
      generator.list_begin( @type)
      super
      generator.list_end( @type)
    end

    def grokked?
      true
    end
  end
end



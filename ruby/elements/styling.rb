require_relative 'unknown'

module Elements
  class Styling < Unknown
    def initialize( place, types)
      super( place)
      @types = types
    end

    def describe
      if @types.size > 0
        super + ': ' + @types.collect {|type| type.to_s}.join( ' ')
      else
        super
      end
    end

    def generate( generator, before, after)
      super( generator, (before + @types).uniq, (after + @types).uniq)
    end

    def grokked?
      true
    end
  end
end



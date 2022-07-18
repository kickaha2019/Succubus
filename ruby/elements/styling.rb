require_relative 'text_group'

module Elements
  class Styling < TextGroup
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

    def generate( generator)
      generator.style_begin( @types)
      super
      generator.style_end( @types)
    end

    def text?
      true
    end
  end
end



require_relative 'group'

module Elements
  class Styling < Group
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
      md = generate_children( generator)
      if generator.textual?( md)
        generator.style( @types, md)
      else
        generator.raw( raw)
      end
    end
  end
end



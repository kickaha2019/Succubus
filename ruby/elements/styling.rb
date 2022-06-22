require_relative 'unknown'

module Elements
  class Styling < Unknown
    def initialize( place, types)
      super( place)
      @types = types
    end

    def describe
      if @types.size > 0
        @types.collect {|type| type.to_s}.join( ' ') + ': ' + super
      else
        super
      end
    end

    def grokked?
      true
    end
  end
end



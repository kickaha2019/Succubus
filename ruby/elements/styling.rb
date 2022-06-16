require_relative 'unknown'

module Elements
  class Styling < Unknown
    def initialize( doc, types, children)
      super( doc, children)
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



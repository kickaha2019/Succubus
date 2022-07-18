require_relative 'group'

module Elements
  class List < Group
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

    def generate( generator)
      generator.list_begin( @type)
      super
      generator.list_end( @type)
    end
  end
end



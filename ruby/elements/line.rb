require_relative 'group'

module Elements
  class Line < Group
    def initialize( place)
      super
    end

    def generate( generator)
      generator.newline( generate_children( generator))
    end
  end
end



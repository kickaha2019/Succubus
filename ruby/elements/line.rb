require_relative 'text_group'

module Elements
  class Line < Group
    def initialize( place)
      super
    end

    def generate( generator)
      generator.newline
      super
      generator.newline
    end
  end
end



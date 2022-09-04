require_relative 'group'

module Elements
  class Heading < Group
    def initialize( place, level)
      super( place)
      @level = level
    end

    def content?
      true
    end

    def describe
      super + ': ' + @level.to_s
    end

    def generate( generator)
      md = generate_children( generator)
      if generator.textual?( md)
        generator.heading( @level, md)
      else
        [raw]
      end
    end
  end
end



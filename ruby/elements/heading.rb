require_relative 'text_group'

module Elements
  class Heading < TextGroup
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
      if text != ''
        generator.heading_begin( @level)
        super( generator)
        generator.heading_end( @level)
      else
        generator.newline
      end
    end
  end
end



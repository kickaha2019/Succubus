require_relative 'unknown'

module Elements
  class Font < Unknown
    def initialize( place)
      super
      @colour = place['color']
      @face   = place['face']
      @size   = place['size']
    end

    def content?
      true
    end

    def describe
      text = []
      if @colour
        text << "Colour: #{@colour}"
      end
      if @face
        text << "Face: #{@face}"
      end
      if @size
        text << "Size: #{@size}"
      end
      text.join( ' ')
    end

    def grokked?
      true
    end
  end
end

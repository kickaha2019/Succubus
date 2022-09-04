require_relative 'group'

module Elements
  class Font < Group
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

      super + ': ' + text.join( ' ')
    end
  end
end

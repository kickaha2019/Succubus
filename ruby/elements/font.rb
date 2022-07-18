require_relative 'text_group'

module Elements
  class Font < TextGroup
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

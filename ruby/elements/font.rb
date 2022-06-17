require_relative 'unknown'

module Elements
  class Font < Unknown
    def initialize( doc, children)
      super( doc, children)
    end

    def content?
      true
    end

    def describe
      text = []
      if doc['color']
        text << "Colour: #{doc['color']}"
      end
      if doc['face']
        text << "Face: #{doc['face']}"
      end
      if doc['size']
        text << "Size: #{doc['size']}"
      end
      text.join( ' ')
    end

    def grokked?
      true
    end
  end
end

require_relative 'unknown'

module Elements
  class Text < Unknown
    def initialize( place, text)
      super( place)
      @text = text
    end

    def content?
      @text.strip != ''
    end

    def describe
      super + ': ' + @text
    end

    def description( generator)
      @text
    end

    def error?
      false
    end

    def generate( generator)
      generator.text( text)
    end

    def grokked?
      true
    end

    def text
      @text
    end
  end
end



require_relative 'text_group'

module Elements
  class Cell < TextGroup
    def initialize( place)
      super
      @header = (place.name == 'TH')
    end

    def content?
      true
    end

    def generate( generator)
      generator.cell( text)
    end

    def header?
      @header
    end
  end
end

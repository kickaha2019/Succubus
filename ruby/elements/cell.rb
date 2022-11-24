require_relative 'group'

module Elements
  class Cell < Group
    def initialize( place)
      super
      @header = (place.name == 'TH')
    end

    def content?
      true
    end

    def description( generator)
      ''
    end

    def generate( generator)
      generator.raw( raw)
    end

    def header?
      @header
    end
  end
end

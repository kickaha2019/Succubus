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

    def generate( generator)
      [raw]
    end

    def header?
      @header
    end
  end
end

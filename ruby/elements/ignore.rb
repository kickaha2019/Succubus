require_relative 'unknown'

module Elements
  class Ignore < Unknown
    def children
    end

    def content?
      false
    end

    def description( generator)
      ''
    end

    def description_image( generator)
      nil
    end

    def generate( generator)
      []
    end

    def grokked?
      true
    end

    def text
      ''
    end
  end
end



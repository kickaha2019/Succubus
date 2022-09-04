require_relative 'unknown'

module Elements
  class Ignore < Unknown
    def content?
      false
    end

    def children
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



require_relative 'unknown'

module Elements
  class Ignore < Unknown
    def children
    end

    def content?
      false
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



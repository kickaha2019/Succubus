require_relative 'unknown'

module Elements
  class Ignore < Unknown
    def content?
      false
    end

    def generate( generator)
    end

    def grokked?
      true
    end

    def text
      ''
    end

    def tree
      yield self
    end
  end
end



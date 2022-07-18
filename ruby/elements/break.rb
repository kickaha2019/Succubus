require_relative 'unknown'

module Elements
  class Break < Unknown
    def error?
      return true, 'Has content' if content?
      false
    end

    def generate( generator)
      generator.newline
      generator.newline( true)
    end

    def grokked?
      true
    end
  end
end



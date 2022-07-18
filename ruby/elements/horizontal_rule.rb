require_relative 'unknown'

module Elements
  class HorizontalRule < Unknown
    def error?
      content?
    end

    def generate( generator)
      newline
      generator.hr
      newline
    end

    def grokked?
      true
    end
  end
end



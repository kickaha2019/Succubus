require_relative 'unknown'

module Elements
  class HorizontalRule < Unknown
    def error?
      content?
    end

    def generate( generator)
      generator.newline
      generator.hr
      generator.newline
    end

    def grokked?
      true
    end
  end
end



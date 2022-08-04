require_relative 'text_group'

module Elements
  class Paragraph < Group
    def generate( generator)
      generator.paragraph_begin
      super
      generator.paragraph_end
    end

    def text?
      children do |child|
        return false unless child.text?
      end
      true
    end
  end
end



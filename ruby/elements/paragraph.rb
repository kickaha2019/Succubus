require_relative 'group'

module Elements
  class Paragraph < Group
    def generate( generator)
      generator.paragraph_begin
      super
      generator.paragraph_end
    end
  end
end



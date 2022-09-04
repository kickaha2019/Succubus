require_relative 'group'

module Elements
  class Paragraph < Group
    def generate( generator)
      generator.paragraph( generate_children( generator))
    end
  end
end



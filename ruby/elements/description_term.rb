require_relative 'group'

module Elements
  class DescriptionTerm < Group
    def description( generator)
      ''
    end

    def generate( generator)
      generator.raw( raw)
    end
  end
end

require_relative 'group'

module Elements
  class DescriptionTerm < Group
    def generate( generator)
      generator.raw( raw)
    end
  end
end

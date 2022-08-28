require_relative 'group'

module Elements
  class DescriptionList < Group
    def content?
      true
    end

    def error?
      @contents.each do |child|
        if child.is_a?( DescriptionTerm)
        elsif child.is_a?( Description)
        else
          return true if child.content?
        end
      end
      false
    end

    def generate( generator)
      @contents.each do |child|
        if child.is_a?( DescriptionTerm)
          generator.description_term( child)
        elsif child.is_a?( Description)
          generator.description( child)
        end
      end
    end
  end
end



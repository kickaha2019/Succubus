require_relative 'group'

module Elements
  class DescriptionList < Group
    def content?
      true
    end

    def generate( generator)
      list = []
      @contents.each do |child|
        md = child.generate_children( generator)
        if child.is_a?( DescriptionTerm)
          return generate_children( generator) unless generator.textual?( md)
          list << [md]
        elsif child.is_a?( Description)
          return generate_children( generator) unless generator.textual?( md)
          return generate_children( generator) if list.empty?
          list[-1] << md
        elsif child.content?
          return generate_children( generator)
        end
      end

      if debug?
        p list
      end
      generator.description_list( list)
    end
  end
end



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
          return [raw] unless generator.textual?( md)
          list << [[md.join( ' ')]]
        elsif child.is_a?( Description)
          return [raw] unless generator.textual?( md)
          return [raw] if list.empty?
          list[-1] << md.join( ' ')
        elsif child.content?
          return [raw]
        end
      end
      generator.description_list( list)
    end
  end
end



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
          return generator.raw( raw) unless generator.textual?( md)
          list << [md]
        elsif child.is_a?( Description)
          return generator.raw( raw) unless generator.textual?( md)
          return generator.raw( raw) if list.empty?
          list[-1] << md
        elsif child.content?
          return generator.raw( raw)
        end
      end
      generator.description_list( list)
    end
  end
end



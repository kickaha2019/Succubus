require_relative 'group'

module Elements
  class List < Group
    def initialize( place, type)
      super( place)
      @type = type
    end

    def content?
      true
    end

    def describe
      super + ': ' + @type.to_s
    end

    def description( generator)
      ''
    end

    def description_image( generator)
      nil
    end

    def generate( generator)
      list = []
      @contents.each do |child|
        if child.is_a?( ListItem)
          md = child.generate_children( generator)
          return generator.raw( raw) unless generator.nestable?( md)
          list << md
        elsif child.content?
          return generator.raw( raw)
        end
      end
      generator.list( @type, list)
    end
  end
end



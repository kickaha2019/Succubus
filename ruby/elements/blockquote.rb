require_relative 'group'

module Elements
  class Blockquote < Group
    def generate( generator)
      md = generate_children( generator)
      if generator.nestable?( md)
        generator.blockquote( md)
      else
        [raw]
      end
    end
  end
end



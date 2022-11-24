require_relative 'group'

module Elements
  class ListItem < Group
    def content?
      true
    end

    def description( generator)
      ''
    end

    def generate( generator)
      generator.raw( raw)
    end
  end
end



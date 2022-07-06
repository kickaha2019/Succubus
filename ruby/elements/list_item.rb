require_relative 'unknown'

module Elements
  class ListItem < Unknown
    def initialize( place)
      super
    end

    def content?
      true
    end

    def generate( generator, before, after)
      generator.list_item_begin
      super
      generator.list_item_end
    end

    def grokked?
      true
    end
  end
end



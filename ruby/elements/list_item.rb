require_relative 'group'

module Elements
  class ListItem < Group
    def content?
      true
    end

    def generate( generator)
      generator.list_item_begin
      super
      generator.list_item_end
    end
  end
end



require_relative 'text_group'

module Elements
  class Span < TextGroup
    def text?
      children_text?
    end
  end
end



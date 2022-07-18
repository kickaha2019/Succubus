require_relative 'group'

module Elements
  class Blockquote < Group
    def generate( generator)
      generator.blockquote_begin
      super
      generator.blockquote_end
    end
  end
end



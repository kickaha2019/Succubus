require_relative 'text_group'

module Elements
  class Pre < TextGroup
    def content?
      true
    end

    def generate( generator)
      generator.pre_begin
      super( generator)
      generator.pre_end
    end
  end
end



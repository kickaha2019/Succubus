require_relative 'blockquote'

module Elements
  class Description < Group
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



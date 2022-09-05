require_relative 'group'

module Elements
  class Pre < Group
    def content?
      true
    end

    def generate( generator)
      generator.raw( raw)
    end
  end
end



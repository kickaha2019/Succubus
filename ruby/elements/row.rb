require_relative 'group'

module Elements
  class Row < Group
    def content?
      true
    end

    def header?
      @contents.each do |child|
        if child.is_a?( Elements::Cell)
          return false unless child.header?
        end
      end
      true
    end

    def generate( generator)
      [raw]
    end
  end
end



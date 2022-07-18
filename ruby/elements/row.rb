require_relative 'group'

module Elements
  class Row < Group
    def content?
      true
    end

    def error?
      @contents.each do |child|
        unless child.is_a?( Elements::Cell)
          return true, 'Child with content but not a cell' if child.content?
        end
      end
      false
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
      generator.row_begin
      super
      generator.row_end
    end
  end
end



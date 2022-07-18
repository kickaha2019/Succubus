require_relative 'group'

module Elements
  class Table < Group
    def content?
      true
    end

    def error?
      @contents.each do |child|
        unless child.is_a?( Elements::Row)
          return true, 'Child with content but not a row' if child.content?
        end
      end

      @contents.each do |child|
        if child.is_a?( Elements::Row)
          return true, 'No header row' unless child.header?
          return false
        end
      end

      true
    end

    def generate( generator)
      generator.table_begin
      super
      generator.table_end
    end
  end
end



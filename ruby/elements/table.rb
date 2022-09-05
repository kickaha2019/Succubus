require_relative 'group'

module Elements
  class Table < Group
    def content?
      true
    end

    def generate( generator)
      rows, header = [], true
      @contents.each do |child|
        if child.is_a?( Elements::Row)
          row = generate_row( generator, child, header)
          return generator.raw( raw) if row.nil?
          rows << row
          header = false
        elsif child.content?
          return generator.raw( raw)
        end
      end

      generator.table( rows)
    end

    def generate_row( generator, row, header)
      cells = []
      row.contents.each do |child|
        if child.is_a?( Elements::Cell)
          return nil unless header == child.header?
          md = child.generate_children( generator)
          return nil unless generator.textual?( md)
          cells << md.join(' ')
        elsif child.content?
          return nil
        end
      end
      cells
    end
  end
end



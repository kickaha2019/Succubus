require_relative 'unknown'

module Elements
  class DescriptionList < Unknown
    def initialize( place)
      super( place)
    end

    def content?
      true
    end

    def generate( generator, before, after)
      generator.table_begin
      generator.row_begin
      generator.cell_begin
      generator.text( 'Term')
      generator.cell_end
      generator.cell_begin
      generator.text( 'Description')
      generator.cell_end
      generator.row_end

      row_started = false
      @contents.each do |child|
        if child.is_a?( DescriptionTerm)
          generator.row_end if row_started
          generator.row_begin
          generator.cell_begin
          generator.text( child.text)
          generator.cell_end
          row_started = true
        end
        if child.is_a?( Description)
          generator.cell_begin
          generator.text( child.text)
          generator.cell_end
        end
      end

      generator.row_end if row_started
      generator.table_end
    end

    def grokked?
      true
    end
  end
end



require_relative 'group'

module Elements
  class Debug < Group
    def generate( generator)
      md = super
      puts "\nDEBUG: #{@element['debug']}"
      p md
      puts "\n"
      md
    end
  end
end



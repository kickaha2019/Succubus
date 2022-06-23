require_relative 'unknown'

module Elements
  class Date < Unknown
    def initialize( place, date)
      super( place)
      @date = date
    end

    def describe
      super + ': ' + @date.to_s
    end

    def grokked?
      true
    end
  end
end



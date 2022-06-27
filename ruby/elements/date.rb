require_relative 'unknown'

module Elements
  class Date < Unknown
    def initialize( place, date)
      super( place)
      @date = date
    end

    def describe
      super + ': ' + @date.strftime( '%Y-%m-%d')
    end

    def grokked?
      true
    end
  end
end



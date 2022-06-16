require_relative 'unknown'

module Elements
  class Date < Unknown
    def initialize( doc, date)
      super( doc, [])
      @date = date
    end

    def describe
      @date.to_s
    end

    def grokked?
      true
    end
  end
end



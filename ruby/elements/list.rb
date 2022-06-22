require_relative 'unknown'

module Elements
  class List < Unknown
    def initialize( place, type)
      super( place)
      @type = type
    end

    def content?
      true
    end

    def describe
      @type.to_s + ': ' + super
    end

    def grokked?
      true
    end
  end
end



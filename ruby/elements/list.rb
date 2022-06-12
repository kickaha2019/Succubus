require_relative 'unknown'

module Elements
  class List < Unknown
    def initialize( doc, type, children)
      super( doc, children)
      @type = type
    end

    def content?
      true
    end

    def describe
      @type.to_s
    end

    def grokked?
      true
    end
  end
end



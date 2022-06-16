module Elements
  class Unknown
    attr_reader :index, :doc, :contents
    @@next_index = 0

    def initialize( doc, contents)
      @@next_index += 1
      @index       = @@next_index
      @doc         = doc
      @contents    = contents
    end

    def content?
      false
    end

    def describe
      @doc['class'] ? @doc['class'] : ''
    end

    def grokked?
      false
    end

    def self.reset_next_index
      @@next_index = 0
    end
  end
end

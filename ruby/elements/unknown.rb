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
      @contents.inject( false) {|flag, child| flag | child.content?}
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

    def text
      @contents.inject( '') {|text, child| text + ' ' + child.text}
    end
  end
end

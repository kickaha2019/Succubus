module Elements
  class Unknown
    attr_reader :index, :doc, :contents

    def initialize( index, doc, contents)
      @index    = index
      @doc      = doc
      @contents = contents
    end
  end
end

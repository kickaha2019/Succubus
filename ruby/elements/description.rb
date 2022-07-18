require_relative 'blockquote'

module Elements
  class Description < Blockquote
    def content?
      true
    end
  end
end



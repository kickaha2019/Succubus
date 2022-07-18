require_relative 'group'

module Elements
  class TextGroup < Group
    def error?
      unless children_text?
        return true, 'Non text children'
      end
      false
    end
  end
end



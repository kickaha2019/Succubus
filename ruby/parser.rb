require_relative 'elements/text'

class Parser
  class Rule
    def initialize( block, args = {})
      @args  = args
      @block = block
    end

    def applies?
      true
    end

    def apply
      @block.call
    end
  end

  def initialize
    Elements::Unknown.reset_next_index
    @rules = Hash.new {|h,k| h[k] = []}
    @rules['TEXT'] << Rule.new( Proc.new {
      Elements::Text.new( element, element.content)
    })
  end

  def children
    @children
  end

  def element
    @element
  end

  def parse( doc)
    contents = doc.children.collect {|child| parse( child)}

    grokked = true
    contents.each {|child| grokked = false unless child.grokked?}

    if grokked
      @element  = doc
      @children = contents

      @rules[doc.name.upcase].each do |rule|
        if rule.applies?
          if result = rule.apply
            return result
          end
        end
      end
    end

    Elements::Unknown.new( doc, contents)
  end
end

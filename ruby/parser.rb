require_relative 'elements/anchor'
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

    on 'a' do
      if element['href']
        Elements::Anchor.new( element, element['href'], children)
      else
        nil
      end
    end

    on 'text' do
      Elements::Text.new( element, element.content)
    end
  end

  def children
    @children
  end

  def element
    @element
  end

  def on( name, args={}, &block)
    @rules[name.upcase] << Rule.new( block, args)
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

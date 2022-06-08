require_relative 'elements/unknown'

class Parser
  def initialize
    @index = 0
  end

  def parse( doc)
    contents =  doc.children.collect {|child| parse( child)}
    @index   += 1
    Elements::Unknown.new( @index, doc, contents)
  end
end

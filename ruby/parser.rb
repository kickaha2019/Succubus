require_relative 'elements/anchor'
require_relative 'elements/break'
require_relative 'elements/cell'
require_relative 'elements/heading'
require_relative 'elements/ignore'
require_relative 'elements/image'
require_relative 'elements/list'
require_relative 'elements/list_item'
require_relative 'elements/paragraph'
require_relative 'elements/row'
require_relative 'elements/span'
require_relative 'elements/styling'
require_relative 'elements/table'
require_relative 'elements/text'

class Parser
  class Rule
    def initialize( block, args = {})
      @args  = args
      @block = block
    end

    def applies?( element)
      if @args['class']
        if args['class'] == ''
          return false if @args['class']
        else
          return false unless @args['class'] && @args['class'].split( ' ').includes?( @args['class'])
        end
      end
      true
    end

    def apply
      @block.call
    end
  end

  def initialize( dir)
    Elements::Unknown.reset_next_index
    @rules = Hash.new {|h,k| h[k] = []}

    if File.exist?( dir + '/rules.rb')
      require dir + '/rules.rb'
      define_rules
    end

    on 'a' do
      if element['href']
        Elements::Anchor.new( element, element['href'], children)
      else
        Elements::Text.new( element, '')
      end
    end

    on 'b' do
      Elements::Styling.new( element, :bold, children)
    end

    on 'br' do
      Elements::Break.new( element)
    end

    on 'h2' do
      Elements::Heading.new( element, 2, children)
    end

    on 'h3' do
      Elements::Heading.new( element, 3, children)
    end

    on 'i' do
      Elements::Styling.new( element, :italic, children)
    end

    on 'img' do
      Elements::Image.new( element, element['src'])
    end

    on 'li' do
      Elements::ListItem.new( element, children)
    end

    on 'p' do
      Elements::Paragraph.new( element, children)
    end

    on 'span' do
      Elements::Span.new( element, children)
    end

    on 'table' do
      Elements::Table.new( element, children)
    end

    on 'td' do
      Elements::Cell.new( element, children)
    end

    on 'text' do
      Elements::Text.new( element, element.content)
    end

    on 'th' do
      Elements::Cell.new( element, children)
    end

    on 'tr' do
      Elements::Row.new( element, children)
    end

    on 'ul' do
      Elements::List.new( element, :unordered, children)
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
        if rule.applies?( doc)
          if result = rule.apply
            return result
          end
        end
      end
    end

    Elements::Unknown.new( doc, contents)
  end
end

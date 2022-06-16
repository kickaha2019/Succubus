require_relative 'elements/anchor'
require_relative 'elements/break'
require_relative 'elements/cell'
require_relative 'elements/date'
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

    def applies?( element, children)
      if (! @args.has_key?( :grokked)) || @args[:grokked]
        children.each do |child|
          return false unless child.grokked?
        end
      end

      if @args[:class]
        if @args[:class] == ''
          # p [element['class'].nil?, element['class'], element.classes]
          # raise 'Dev'
          element['class'].nil?
        else
          element.classes.include?( @args[:class])
        end
      else
        true
      end
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
      Elements::Styling.new( element, [:bold], children)
    end

    on 'big' do
      Elements::Styling.new( element, [:big], children)
    end

    on 'br' do
      Elements::Break.new( element)
    end

    on 'comment' do
      Elements::Ignore.new( element, children)
    end

    on 'div' do
      content = children.inject( false) {|flag, child| flag | child.content?}
      content ? nil : Elements::Ignore.new( element, children)
    end

    on 'em' do
      Elements::Styling.new( element, [:emphasized], children)
    end

    on 'form' do
      Elements::Ignore.new( element, children)
    end

    on 'h2' do
      Elements::Heading.new( element, 2, children)
    end

    on 'h3' do
      Elements::Heading.new( element, 3, children)
    end

    on 'i' do
      Elements::Styling.new( element, [:italic], children)
    end

    on 'img' do
      Elements::Image.new( element, element['src'])
    end

    on 'input' do
      Elements::Ignore.new( element, children)
    end

    on 'label' do
      Elements::Ignore.new( element, children)
    end

    on 'li' do
      Elements::ListItem.new( element, children)
    end

    on 'nav' do
      Elements::Ignore.new( element, children)
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
    @children = doc.children.collect {|child| parse( child)}
    @element  = doc

    @rules[doc.name.upcase].each do |rule|
      if rule.applies?( doc, @children)
        if result = rule.apply
          return result
        end
      end
    end

    Elements::Unknown.new( doc, @children)
  end

  def to_text( children)
    children.inject( '') {|text, child| text + ' ' + child.text}
  end
end

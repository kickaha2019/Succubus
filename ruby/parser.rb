require 'nokogiri'
require 'yaml'

require_relative 'elements/anchor'
require_relative 'elements/article'
require_relative 'elements/break'
require_relative 'elements/cell'
require_relative 'elements/date'
require_relative 'elements/font'
require_relative 'elements/heading'
require_relative 'elements/horizontal_rule'
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
  class ElementRule
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

    def apply( element, children)
      @block.call( element, children)
    end
  end

  class PageRule
    def initialize( expression, block, args = {})
      @expr  = expression
      @args  = args
      @block = block
    end

    def applies?( relative_url, document)
      if @expr.is_a?( String)
        @expr == relative_url
      else
        @expr =~ relative_url
      end
    end

    def apply( relative_url, document)
      @block.call( relative_url, document)
    end
  end

  def initialize( dir)
    @config           = YAML.load( IO.read( dir + '/config.yaml'))
    @element_rules    = Hash.new {|h,k| h[k] = []}
    @page_rules       = []
    @taxonomy         = {}
    @initialised      = false
    @page_initialised = false

    if File.exist?( dir + '/rules.rb')
      require dir + '/rules.rb'
      define_rules
    end

    on_element 'a' do  |element, children|
      if element['href']
        Elements::Anchor.new( element, absolute_url( element['href']), children)
      else
        Elements::Text.new( element, '')
      end
    end
    on_element 'article' do  |element, children|
      content = children.inject( false) {|flag, child| flag | child.content?}
      content ? nil : Elements::Ignore.new( element, children)
    end

    on_element 'b' do  |element, children|
      Elements::Styling.new( element, [:bold], children)
    end

    on_element 'big' do  |element, children|
      Elements::Styling.new( element, [:big], children)
    end

    on_element 'br' do  |element, children|
      Elements::Break.new( element)
    end

    on_element 'code' do  |element, children|
      Elements::Styling.new( element, [:code], children)
    end

    on_element 'comment' do  |element, children|
      Elements::Ignore.new( element, children)
    end

    on_element 'div' do  |element, children|
      content = children.inject( false) {|flag, child| flag | child.content?}
      content ? nil : Elements::Ignore.new( element, children)
    end

    on_element 'em' do  |element, children|
      Elements::Styling.new( element, [:emphasized], children)
    end

    on_element 'font' do  |element, children|
      Elements::Font.new( element, children)
    end

    on_element 'form' do  |element, children|
      Elements::Ignore.new( element, children)
    end

    on_element 'hr' do  |element, children|
      Elements::HorizontalRule.new( element)
    end

    on_element 'h1' do  |element, children|
      Elements::Heading.new( element, 1, children)
    end

    on_element 'h2' do  |element, children|
      Elements::Heading.new( element, 2, children)
    end

    on_element 'h3' do  |element, children|
      Elements::Heading.new( element, 3, children)
    end

    on_element 'h4' do  |element, children|
      Elements::Heading.new( element, 3, children)
    end

    on_element 'h5' do  |element, children|
      Elements::Heading.new( element, 3, children)
    end

    on_element 'i' do  |element, children|
      Elements::Styling.new( element, [:italic], children)
    end

    on_element 'img' do  |element, children|
      Elements::Image.new( element, absolute_url( element['src']))
    end

    on_element 'image' do  |element, children|
      Elements::Image.new( element, absolute_url( element['src']))
    end

    on_element 'input' do  |element, children|
      Elements::Ignore.new( element, children)
    end

    on_element 'label' do  |element, children|
      Elements::Ignore.new( element, children)
    end

    on_element 'li' do  |element, children|
      Elements::ListItem.new( element, children)
    end

    on_element 'medium' do  |element, children|
      Elements::Styling.new( element, [:medium], children)
    end

    on_element 'nav', :grokked => false do  |element, children|
      Elements::Ignore.new( element, children)
    end

    on_element 'ol' do  |element, children|
      Elements::List.new( element, :ordered, children)
    end

    on_element 'p' do  |element, children|
      Elements::Paragraph.new( element, children)
    end

    on_element 'pre' do  |element, children|
      Elements::Styling.new( element, [:pre], children)
    end

    on_element 'section' do  |element, children|
      content = children.inject( false) {|flag, child| flag | child.content?}
      content ? nil : Elements::Ignore.new( element, children)
    end

    on_element 'small' do  |element, children|
      Elements::Styling.new( element, [:small], children)
    end

    on_element 'span' do  |element, children|
      Elements::Span.new( element, children)
    end

    on_element 'strong' do  |element, children|
      Elements::Styling.new( element, [:bold], children)
    end

    on_element 'table' do  |element, children|
      Elements::Table.new( element, children)
    end

    on_element 'tbody' do  |element, children|
      Elements::Styling.new( element, [], children)
    end

    on_element 'td' do  |element, children|
      Elements::Cell.new( element, children)
    end

    on_element 'text' do  |element, children|
      Elements::Text.new( element, element.content)
    end

    on_element 'th' do  |element, children|
      Elements::Cell.new( element, children)
    end

    on_element 'thead' do  |element, children|
      Elements::Styling.new( element, [], children)
    end

    on_element 'tr' do  |element, children|
      Elements::Row.new( element, children)
    end

    on_element 'ul' do  |element, children|
      Elements::List.new( element, :unordered, children)
    end

    @initialised = true
  end

  def absolute_url( url)
    dir_url = @page_url
    if /\/$/ =~ dir_url
      dir_url = dir_url[0..-2]
    else
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    while /^\.\.\// =~ url
      url     = url[3..-1]
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    if /^\// =~ url
      return @base_url + url[1..-1]
    end

    if /^\w*:/ =~ url
      url
    else
      dir_url + '/' + url
    end
  end

  def asset_url( url)
    /\.(jpeg|jpg|gif|png|pdf)$/i =~ url
  end

  def base_url
    @base_url
  end

  def get_text_by_class( document, clazz)
    document.css( '.' + clazz).text.strip
  end

  def on_element(name, args={}, &block)
    raise 'Element rules must be defined in initialisation of parser' if @initialised #|| @page_initialised
    @element_rules[name.upcase] << ElementRule.new(block, args)
  end

  def on_page( expression, args={}, &block)
    raise 'Page rules must be defined in initialisation of parser' if @initialised
    @page_initialised = true
    @page_rules << PageRule.new( expression, block, args)
    @page_initialised = false
  end

  def page_url
    @page_url
  end

  def parse( url, page)
    Elements::Unknown.reset_next_index

    html_doc    = Nokogiri::HTML( page)
    @base_url   = @config['root_url']
    @page_url   = url
    @page_title = nil

    relative_url = @page_url[@base_url.size..-1]

    @page_rules.each do |rule|
      if rule.applies?( relative_url, html_doc)
        rule.apply( relative_url, html_doc)
        break
      end
    end

    parse1( html_doc.root.at_xpath( '//body'))
  end

  def parse1( doc)
    children = doc.children.collect {|child| parse1( child)}
    element  = doc

    @element_rules[doc.name.upcase].each do |rule|
      if rule.applies?( doc, children)
        if result = rule.apply( element, children)
          return result
        end
      end
    end

    Elements::Unknown.new( doc, children)
  end

  def taxonomy( name, plural = nil)
    raise 'Taxonomy must be defined in initialisation of parser' unless @initialised
    raise "Taxonomy #{name} already defined" if @taxonomy[name]
    @taxonomy[name] = plural ? plural : name
  end

  def title( text)
    @page_title = text
  end

  def to_text( children)
    children.inject( '') {|text, child| text + ' ' + child.text}
  end
end

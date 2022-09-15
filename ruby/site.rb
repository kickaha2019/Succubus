require 'nokogiri'
require 'yaml'

require_relative 'nodes'
require_relative 'place'
require_relative 'page'
require_relative 'elements/anchor'
require_relative 'elements/article'
require_relative 'elements/blockquote'
require_relative 'elements/break'
require_relative 'elements/caption'
require_relative 'elements/cell'
require_relative 'elements/debug'
require_relative 'elements/description'
require_relative 'elements/description_list'
require_relative 'elements/description_term'
require_relative 'elements/font'
require_relative 'elements/heading'
require_relative 'elements/horizontal_rule'
require_relative 'elements/ignore'
require_relative 'elements/image'
require_relative 'elements/line'
require_relative 'elements/list'
require_relative 'elements/list_item'
require_relative 'elements/paragraph'
require_relative 'elements/pre'
require_relative 'elements/row'
require_relative 'elements/span'
require_relative 'elements/styling'
require_relative 'elements/table'
require_relative 'elements/text'

class Site
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

      applies = true

      if @args[:class]
        if @args[:class] == ''
          # p [element['class'].nil?, element['class'], element.classes]
          # raise 'Dev'
          applies = element['class'].nil?
        else
          applies = element.classes.include?( @args[:class])
        end
      end

      if applies
        if @args[:style]
          applies = (@args[:style] =~ element['style'])
        end
      end

      if applies
        if @args[:parent]
          applies = element.parent && (element.parent.name == @args[:parent])
        end
      end

      if applies
        if @args[:grandparent]
          applies = element.parent && element.parent.parent && (element.parent.parent.name == @args[:grandparent])
        end
      end

      if applies
        if @args[:attribute]
          applies = ! element[@args[:attribute]].nil?
        end
      end

      applies
    end

    def apply( place)
      @block.call( place)
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

    def apply( page)
      @block.call( page)
    end
  end

  def initialize( config)
    @config             = config
    @element_rules      = Hash.new {|h,k| h[k] = []}
    @page_rules         = []
    @taxonomy           = {}
    @initialised        = false
    @page_initialised   = true
    @page_element_rules = {}

    define_rules
    @initialised = true

    @url_replaces = {}
    @config['url_replace'].each do |replace|
      @url_replaces[replace['from']] = replace['to']
    end
  end

  def absolutise( page_url, url)
    url      = url.strip.gsub( '%20', ' ')
    url      = url.gsub( /.\/\//) do |match|
      (match == '://' ? match : match[0..1])
    end
    root_url = @config['root_url']
    dir_url  = page_url.split('?')[0]

    if /^\?/ =~ url
      return dir_url + url
    end

    if /\/$/ =~ dir_url
      dir_url = dir_url[0..-2]
    else
      dir_url = dir_url.split('/')[0..-2].join('/')
    end

    # while /^\.\.\// =~ url
    #   url     = url[3..-1]
    #   dir_url = dir_url.split('/')[0..-2].join('/')
    # end

    if /^\// =~ url
      url = root_url + url[1..-1]
    elsif /^\w*:/ =~ url
    else
      url = dir_url + '/' + url
    end

    old_url = ''
    while old_url != url
      old_url = url
      url = url.sub( /\/[a-z0-9_\-]+\/\.\.\//i, '/')
    end

    if (url.size > root_url.size) && (/\/$/ =~ url)
      url = url[0..-2]
    end

    url1 = url.sub( /^http:/, 'https:')
    if local?(url1)
      url = url1
    end

    if @url_replaces[url]
      url = @url_replaces[url]
    end

    url
  end

  def asset?( url)
    ! html?( url)
  end

  def define_rules
    on_element 'a' do  |place|
      if place['href']
        Elements::Anchor.new(place, place.absolutise(place['href']), place['title'])
      else
        Elements::Text.new( place, '')
      end
    end

    on_element 'article' do  |place|
      place.content? ? nil : Elements::Ignore.new( place)
    end

    on_element 'b' do  |place|
      Elements::Styling.new( place, [:bold])
    end

    on_element 'big' do  |place|
      Elements::Styling.new( place, [:big])
    end

    on_element 'blockquote' do  |place|
      Elements::Blockquote.new( place)
    end

    on_element 'br' do  |place|
      Elements::Break.new( place)
    end

    on_element 'caption' do  |place|
      Elements::Caption.new( place)
    end

    on_element 'center' do  |place|
      Elements::Group.new( place)
    end

    on_element 'cite' do  |place|
      Elements::Styling.new( place, [:cite])
    end

    on_element 'code' do  |place|
      Elements::Styling.new( place, [:code])
    end

    on_element 'comment' do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'dd' do  |place|
      Elements::Description.new( place)
    end

    on_element 'del' do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'div' do  |place|
      place.content? ? nil : Elements::Ignore.new( place)
    end

    on_element 'dl' do  |place|
      Elements::DescriptionList.new( place)
    end

    on_element 'dt' do  |place|
      Elements::DescriptionTerm.new( place)
    end

    on_element 'em' do  |place|
      Elements::Styling.new( place, [:emphasized])
    end

    on_element 'font' do  |place|
      Elements::Font.new( place)
    end

    on_element 'form' do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'header' do  |place|
      Elements::Styling.new( place, [])
    end

    on_element 'hr' do  |place|
      Elements::HorizontalRule.new( place)
    end

    on_element 'h1' do  |place|
      Elements::Heading.new( place, 1)
    end

    on_element 'h2' do  |place|
      Elements::Heading.new( place, 2)
    end

    on_element 'h3' do  |place|
      Elements::Heading.new( place, 3)
    end

    on_element 'h4' do  |place|
      Elements::Heading.new( place, 3)
    end

    on_element 'h5' do  |place|
      Elements::Heading.new( place, 3)
    end

    on_element 'i' do  |place|
      Elements::Styling.new( place, [:italic])
    end

    on_element 'img' do  |place|
      Elements::Image.new(place, place.absolutise(place['src']), place['title'])
    end

    on_element 'image' do  |place|
      Elements::Image.new(place, place.absolutise(place['src']), place['title'])
    end

    on_element 'input' do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'ins' do  |place|
      Elements::Styling.new( place, [:inserted])
    end

    on_element 'kbd' do  |place|
      Elements::Styling.new( place, [:keyboard])
    end

    on_element 'label' do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'li' do  |place|
      Elements::ListItem.new( place)
    end

    on_element 'link' do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'medium' do  |place|
      Elements::Styling.new( place, [:medium])
    end

    on_element 'meta', :grokked => false do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'nav', :grokked => false do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'nobr' do  |place|
      Elements::Line.new( place)
    end

    on_element 'ol' do  |place|
      ol = Elements::List.new( place, :ordered)
    end

    on_element 'p' do  |place|
      Elements::Paragraph.new( place)
    end

    on_element 'pre' do  |place|
      Elements::Pre.new( place)
    end

    on_element 'script', :grokked => false do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'section' do  |place|
      place.content? ? nil : Elements::Ignore.new( place)
    end

    on_element 'small' do  |place|
      Elements::Styling.new( place, [:small])
    end

    on_element 'span' do  |place|
      Elements::Span.new( place)
    end

    on_element 'strike' do  |place|
      Elements::Styling.new( place, [:strike])
    end

    on_element 'strong' do  |place|
      Elements::Styling.new( place, [:bold])
    end

    on_element 'style', :grokked => false do  |place|
      Elements::Ignore.new( place)
    end

    on_element 'sub' do  |place|
      Elements::Styling.new( place, [:subscript])
    end

    on_element 'sup' do  |place|
      Elements::Styling.new( place, [:superscript])
    end

    on_element 'table' do  |place|
      Elements::Table.new( place)
    end

    on_element 'tbody' do  |place|
      Elements::Styling.new( place, [])
    end

    on_element 'td' do  |place|
      Elements::Cell.new( place)
    end

    on_element 'text' do  |place|
      Elements::Text.new( place, place.text)
    end

    on_element 'th' do  |place|
      Elements::Cell.new( place)
    end

    on_element 'thead' do  |place|
      Elements::Styling.new( place, [])
    end

    on_element 'tr' do  |place|
      Elements::Row.new( place)
    end

    on_element 'tt' do  |place|
      Elements::Styling.new( place, [:teletype])
    end

    on_element 'u' do  |place|
      Elements::Styling.new( place, [:underline])
    end

    on_element 'ul' do  |place|
      Elements::List.new( place, :unordered)
    end

    on_element 'var' do  |place|
      Elements::Styling.new( place, [:variable])
    end
  end

  def get_text_by_class( document, clazz)
    document.css( '.' + clazz).text.strip
  end

  def html?( url)
    /\/[^\.\/]*(|\.htm|\.html)$/ =~ url
  end

  def local?( url)
    return true unless /^\w*:/ =~ url
    root_url = @config['root_url']
    return false unless url.size > root_url.size
    url[0...root_url.size] == root_url
  end

  def on_element(name, args={}, &block)
    raise 'Element rules must be defined in initialisation of parser or page' if @initialised && @page_initialised
    if @initialised
      @page_element_rules[name.upcase] << ElementRule.new(block, args)
    else
      @element_rules[name.upcase] << ElementRule.new(block, args)
    end
  end

  def on_page( expression, args={}, &block)
    raise 'Page rules must be defined in initialisation of parser' if @initialised
    @page_initialised = true
    @page_rules << PageRule.new( expression, block, args)
    @page_initialised = false
  end

  def page_to_nodes( document)
    Nodes.new( [[document.root.at_xpath( '//body')]])
  end

  def parse( url, html_doc)
    Elements::Unknown.reset_next_id
    page = Page.new( self, @config['root_url'], @taxonomy, url, html_doc)

    relative_url = url[@config['root_url'].size..-1]

    @page_initialised, @page_element_rules = false, Hash.new {|h,k| h[k] = []}
    @page_rules.each do |rule|
      if rule.applies?( relative_url, html_doc)
        break if rule.apply( page)
      end
    end

    @page_initialised = true
    parse1( page, html_doc.root.at_xpath( '//body'))
  end

  def parse1( page, doc)
    children = doc.children.collect {|child| parse1( page, child)}.flatten
    place    = Place.new( page, doc, children)

    if place.debug?
      puts "... #{place.element['debug']}: Parse"
      children.each do |child|
        puts "...  #{child.class.to_s}: #{child.text[0..29].gsub( /\s/, ' ').strip}"
      end
    end

    @page_element_rules[doc.name.upcase].each do |rule|
      if rule.applies?( doc, children)
        if result = rule.apply( place)
          if place.debug?
            puts "... Result: #{result.class.to_s}\n\n"
          end
          return result
        end
      end
    end

    @element_rules[doc.name.upcase].each do |rule|
      if rule.applies?( doc, children)
        if result = rule.apply( place)
          if place.debug?
            puts "... Result: #{result.class.to_s}\n\n"
          end
          return result
        end
      end
    end

    if place.debug?
      puts "... Result: Unknown\n\n"
    end
    Elements::Unknown.new( place)
  end

  def parse_document( path)
    Nokogiri::HTML( IO.read( path))
  end

  def preparse( url, page)
  end

  def redirect( url, target)
  end

  def taxonomy( name, plural = nil)
    raise "Taxonomy #{name} already defined" if @taxonomy[name]
    @taxonomy[name] = plural ? plural : name
  end

  def taxonomies
    @taxonomy.each_pair {|k,v| yield k,v}
  end
end

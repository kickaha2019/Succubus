require_relative 'unknown'

module Elements
  class Article < Unknown
    attr_reader :date, :title, :index, :mode, :root, :url

    def initialize( place)
      super
      @title       = place.page.title
      @date        = place.page.date
      @description = place.page.description
      @mode        = place.page.mode
      @index       = place.page.index
      @root        = place.page.root?
      @root_url    = place.page.root_url
      @url         = place.url
    end

    def article?
      true
    end

    def compile( generator)
      generator.article_markdown( generate( generator))
    end

    def content?
      false
    end

    def description
      @description
    end

    def error?
      return true, 'No mode' unless @mode
      return true, 'No title' unless @title
      if @mode == :post
        return true, 'No date' unless @date
        return true, 'No index' unless @index
      end

      tree do |child|
        return true, 'Article inside article' if child.article? && child != self
      end

      return false, nil
    end

    def grokked?
      false
    end

    def index=( index)
      @index = index
    end

    def relative_url
      @url[@root_url.size..-1]
    end

    def set_date( time)
      @date = time if time
      self
    end

    def set_title( text)
      @title = text if text
      self
    end

    def text
      ''
    end

    def tooltip
      "Article: Title: #{@title} Date: #{@date} Mode: #{@mode} Index: #{@index.join( ' ')}"
    end

    # def tree
    #   yield self
    # end
  end
end



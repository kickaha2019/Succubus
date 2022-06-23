require_relative 'unknown'

module Elements
  class Article < Unknown
    def initialize( place)
      super
      @title = place.page.title
      @date  = place.page.date
      @mode  = place.page.mode
      @tags  = place.page.tags
    end

    def article?
      true
    end

    def content?
      false
    end

    def date( time)
      @date = time if time
      self
    end

    def error?
      return true unless @mode
      return true unless @title
      if @mode == :post
        return true unless @date
        return true unless @tags
      end
      false
    end

    def grokked?
      false
    end

    def text
      ''
    end

    def tooltip
      "Title: #{@title} Date: #{@date}"
    end

    def title( text)
      @title = text if text
      self
    end
  end
end



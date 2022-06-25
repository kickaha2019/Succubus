require_relative 'unknown'

module Elements
  class Article < Unknown
    attr_reader :date, :title, :tags, :mode

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
      "Title: #{@title} Date: #{@date} Mode: #{@mode} Tags: #{@tags.collect {|tag| tag[1]}.join( ' ')}"
    end

    def tree
      yield self
    end
  end
end



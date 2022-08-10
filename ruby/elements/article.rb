require_relative 'unknown'

module Elements
  class Article < Unknown
    attr_reader :date, :title, :tags, :mode, :root

    def initialize( place)
      super
      @title       = place.page.title
      @date        = place.page.date
      @description = place.page.description
      @mode        = place.page.mode
      @tags        = place.page.tags
      @root        = place.page.root?
      @root_url    = place.page.root_url
      @url         = place.url
    end

    def article?
      true
    end

    def content?
      false
    end

    def description
      return @description if @description
      # if @mode == :home
      #   children do |child|
      #     p [child.describe, child.text]
      #   end
      # end
      text = []
      children do |child|
        text << child.text.strip
      end
      text.join( ' ')
    end

    def error?
      return true, 'No mode' unless @mode
      return true, 'No title' unless @title
      if @mode == :post
        return true, 'No date' unless @date
        return true, 'No tags' unless @tags
      end

      tree do |child|
        return true, 'Article inside article' if child.article? && child != self
      end

      return false, nil
    end

    def grokked?
      false
    end

    def raw_count
      count = 0
      tree do |child|
        count += 1 if child.is_a?( Elements::Raw)
      end
      count
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
      "Title: #{@title} Date: #{@date} Mode: #{@mode} Tags: #{@tags.collect {|tag| tag[1]}.join( ' ')}"
    end

    # def tree
    #   yield self
    # end
  end
end



require_relative 'unknown'

module Elements
  class Body < Unknown
    attr_reader :date, :title, :index, :mode, :root, :url

    def initialize( place, ignore=false)
      super( place)
      @title       = place.page.title
      @date        = place.page.date
      @mode        = place.page.mode
      @index       = place.page.index
      @root        = place.page.root?
      @root_url    = place.page.root_url
      @url         = place.url
      @ignore      = ignore
    end

    def children
      super unless @ignore
    end

    def content?
      @ignore ? false : super
    end

    def error?
      return true, 'No mode' unless @mode
      return true, 'No title' unless @title
      if @mode == :post
        return true, 'No date' unless @date
        return true, 'No index' unless @index
      end
      return false, nil
    end

    def grokked?
      @ignore ? true : super
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
      if @ignore
        "Body: Ignored"
      else
        "Body: Title: #{@title} Date: #{@date} Mode: #{@mode} Index: #{@index.join( ' ')}"
      end
    end

    # def tree
    #   yield self
    # end
  end
end


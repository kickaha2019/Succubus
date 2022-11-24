require_relative 'unknown'

module Elements
  class Image < Unknown
    attr_reader :title

    def initialize( place, path, title)
      super( place)
      @path  = path.gsub( /[\s\n]/, '').gsub( /[\(\)]/, '_')
      @title = title
    end

    def content?
      true
    end

    def describe
      super + ': ' + @path
    end

    def description_image( generator)
      if im = generator.localise( @path)
        {'path' => im, 'title' => @title}
      else
        nil
      end
    end

    def generate( generator)
      generator.image( @path, @title)
    end

    def grokked?
      true
    end

    def links
      super {|link| yield link}
      yield @path
    end
  end
end


module Elements
  class PostDate < Unknown
    attr_reader :url, :date

    def initialize( place, url, date)
      super( place)
      @url  = url
      @date = date
    end

    def describe
      super + ': ' + @url + ': ' + @date.strftime( '%Y-%m-%d')
    end

    def links
      yield @url
    end
  end
end

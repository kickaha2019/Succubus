class Relativize
  def edit( file, to_top)
    page = IO.read( file)

    page = page.gsub( /\shref\s*=\s*"\//mi) do
      " href=\"#{to_top}"
    end

    page = page.gsub( / href="[^"]*\/"/m) do |href|
      if /"http(s|):/ =~ href
        href
      else
        href[0..-2] + 'index.html"'
      end
    end

    page = page.gsub( /\ssrc\s*=\s*"\//mi) do
      " src=\"#{to_top}"
    end

    File.open( file, 'w') do |io|
      io.print page
    end
  end

  def process( path, to_top)
    Dir.entries( path).each do |f|
      next if /^\./ =~ f
      path2 = path + '/' + f
      if File.directory?( path2)
        process( path2, to_top + '../')
      elsif /\.html$/ =~ f
        edit( path2, to_top)
      end
    end
  end
end

r = Relativize.new
r.process( ARGV[0], '')


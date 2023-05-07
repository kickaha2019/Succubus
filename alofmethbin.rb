class Alofmethbin
  def asset?( url)
    /\.(jpg|jpeg|png|gif|webp|zip|pdf|doc|rb|txt)$/i =~ url
  end

  def debug_url?( url)
    false
  end

  def html?( url)
    ! asset?( url)
  end

  def include_urls
  end

  def login_redirect_url
    'xxx'
  end

  def on_node( node)
    if node.name == 'img'
      if m = /javascript: showOverlay\( '(.*)'\)/.match( node['onclick'])
        yield m[1]
      end
    end
  end

  def reduce_url( url)
    if m = /^https:(.*)$/.match( url)
      url = 'http:' + m[1]
    end

    if m = /^(http:\/\/[a-zA-Z0-9\.\-_]*):\d+(\/.*)$/.match( url)
      url = m[1] + m[2]
    end

    if m = /^(.*)\/\/www\.(.*)$/.match( url)
      url = m[1] + '//' + m[2]
    end

    if m = /^(.*)\/$/.match( url)
      url = m[1]
    end

    url
  end

  def report_redirect( from, to)
    ! similar_url?( from, to)
  end

  def root_url
    'https://alofmethbin.com/'
  end

  def similar_url?( url1, url2)
    url1 = reduce_url( url1)
    url2 = reduce_url( url2)

    if (url1 + '/') == url2[0..(url1.size)]
      return true
    end

    return true if url1 == url2

    parts1 = url1.split( '/')
    parts2 = url2.split( '/')

    while (parts1.size > 0) && (parts1[0] == parts2[0])
      parts1, parts2 = parts1[1..-1], parts2[1..-1]
    end

    while (parts1.size > 0) && (parts1[-1] == parts2[-1])
      parts1, parts2 = parts1[0..-2], parts2[0..-2]
    end

    parts1.size == 0
    # if m = /^(.*)\/us\/en\/(.*)$/.match( url2)
    #   return true if url1 == "#{m[1]}/#{m[2]}"
    # end
    #
    # url1 == url2
  end

  def simplify_url( url)
    if m = /^(.*)\?origin=/.match( url)
      url = m[1]
    else
      url
    end
  end

  def trace?( url)
    true
  end
end

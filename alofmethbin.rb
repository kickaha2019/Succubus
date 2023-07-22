class Alofmethbin
  def asset?( url)
    /\.(jpg|jpeg|png|gif|webp|zip|pdf|doc|rb|txt)$/i =~ url
  end

  def debug_url?( url)
    false
  end

  def find_links?( url, parsed)
    true
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

  def report_redirect( from, to)
    ! similar_url?( from, to)
  end

  def root_url
    'https://alofmethbin.com/'
  end

  def similar_url?( url1, url2)
    server1, path1 = split_url( url1)
    server2, path2 = split_url( url2)

    if server1.size < server2.size
      server1, server2 = server2, server1
    end

    if server1.size > server2.size
      return false unless server2 == server1[-server2.size..-1]
      return false unless /^\./ =~ server1[(-server2.size-1)..-1]
    else
      return false unless server1 == server2
    end

    return true if path1 == path2

    parts1 = path1.split( '/')
    parts2 = path2.split( '/')

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

  def split_url( url)
    if m = /^http(?:s|):\/\/([^\/]*)$/.match( url)
      return m[1], ''
    end

    if m = /^http(?:s|):\/\/([^\/]*)\/(.*)$/.match( url)
      path = m[2]
      path = path[0...-1] if /\/$/ =~ path
      return m[1], path
    end

    return url, ''
  end

  def trace?( url)
    true
  end
end

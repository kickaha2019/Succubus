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

  def root_url
    'https://alofmethbin.com/'
  end

  def trace?( url)
    true
  end
end

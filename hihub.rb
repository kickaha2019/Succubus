class Hihub
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

  def root_url
    'https://www.hihub.info/'
  end

  def trace?( url)
    return false if /\/\?method=ical&/ =~ url
    return false if /\/\?filter_by=/ =~ url
    return false if /\/\?wpbdp_view=/ =~ url
    true
  end
end

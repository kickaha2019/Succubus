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
    ignore = [
        'https://ico.org.uk/global/contact-us/email/',
        'https://www.hihub.info/wp-content/uploads/2020/11/Newsletter-News-and-Features-2020-10.pdf',
        # https://www.hihub.info/events/members-coffee-morning/
        # https://www.hihub.info/events/proposed-new-science-park-talk/
        # https://www.hihub.info/events/village-society-talk/
        'https://www.hihub.info/wp-content/uploads/2019/09/cropped-schoolhill19081.jpg',
        # https://www.hihub.info/news/virtual-cafe-now-open-for-business/
        # https://www.hihub.info/features/colins-tech-tips-pt-1/
        'https://www.hihub.info/hicafe/'
    ]
    ignore.each do |i|
      return false if i == url
    end
    return false if /\/\?method=ical&/ =~ url
    return false if /\/\?filter_by=/ =~ url
    return false if /\/\?occurrence=/ =~ url
    return false if /\/\?wpbdp_view=/ =~ url
    return false if /^https:\/\/www\.facebook\.com\/sharer\.php\?/ =~ url
    return false if /^https:\/\/www\.facebook\.com\/sharer\/sharer\.php\?/ =~ url
    return false if /^https:\/\/pinterest\.com\/pin\/create\/button\/\?/ =~ url
    return false if /^https:\/\/api\.whatsapp\.com\/send\?/ =~ url
    return false if /^https:\/\/twitter\.com\/share\?/ =~ url
    return false if /^https:\/\/twitter\.com\/intent\/tweet\?/ =~ url
    return false if /^https:\/\/calendar\.google\.com\/calendar\/render\?/ =~ url
    true
  end
end

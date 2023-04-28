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
        # https://www.hihub.info/privacy-policy/
        'https://ico.org.uk/global/contact-us/email/',
        # https://www.hihub.info/printable-versions/
        'https://www.hihub.info/wp-content/uploads/2020/11/Newsletter-News-and-Features-2020-10.pdf',
        # https://www.hihub.info/events/members-coffee-morning/
        # https://www.hihub.info/events/proposed-new-science-park-talk/
        # https://www.hihub.info/events/village-society-talk/
        'https://www.hihub.info/wp-content/uploads/2019/09/cropped-schoolhill19081.jpg',
        # https://www.hihub.info/news/virtual-cafe-now-open-for-business/
        # https://www.hihub.info/features/colins-tech-tips-pt-1/
        'https://www.hihub.info/hicafe/',
        # https://www.hihub.info/events/wi-april-meeting/
        'https://www.hihub.info/wp-content/uploads/2019/09/Cambridge-Federation-badge.gif',
        # https://www.hihub.info/events/hatha-yoga/
        'https://www.hihub.info/events/hatha-yoga/paulineyoga@gmail.com',
        # https://www.hihub.info/events/smokehouse-market/
        # https://www.hihub.info/events/jazz-at-histon-smokehouse/
        # https://www.hihub.info/events/crafty-kids-easter-fair/
        'https://www.hihub.info/wp-content/uploads/2021/08/Histon-Smokehouse-Logo.jpg',
        # https://www.hihub.info/news-in-brief/local-book-launch-for-two-local-authors/
        'https://www.bloomsbury.com/uk/great-hamster-getaway-9781408878934/'
        # NOTIFIED 25th April 2023
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

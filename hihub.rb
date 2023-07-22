class Hihub
  def asset?( url)
    /\.(jpg|jpeg|png|gif|webp|zip|pdf|doc|rb|txt)$/i =~ url
  end

  def debug_url?( url)
    false
  end

  def find_links?( url, parsed)
    past = Time.now - 31 * 24 * 60 * 60
    before, after = 0, 0

    parsed.css( 'time').each do |meta|
      if m = /^(\d\d\d\d)-(\d\d)-(\d\d)T/.match( meta['datetime'])
        if Time.gm( m[1].to_i, m[2].to_i, m[3].to_i) < past
          before += 1
        else
          after += 1
        end
      end
    end

    parsed.css( 'script').each do |script|
      if m = /"endDate":\s*"(\d\d\d\d)-(\d\d)-(\d\d)"/m.match( script.text)
        if Time.gm( m[1].to_i, m[2].to_i, m[3].to_i) < past
          before += 1
        else
          after += 1
        end
      end
    end

    return true if after > 0
    before == 0
  end

  def html?( url)
    ! asset?( url)
  end

  def include_urls
  end

  def login_redirect_url
    'xxx'
  end

  def report_redirect( from, to)
    false
  end

  def root_url
    'https://www.hihub.info/'
  end

  def trace?( url)
    ignore = [
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

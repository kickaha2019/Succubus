class BGA < Site
  def initialize( config)
    super
    taxonomy 'Section', 'Sections'
  end

  def absolutise( page_url, url)
    url = super
    if /^#/ =~ url
      url
    elsif local? url
      page_param_only( url.split('#')[0])
    else
      url
    end
  end

  def collect_news_posts( page, place)
    result = Elements::Body.new( place, true)
    nodes = Nodes.new( [[place.element]])
    nodes.css( 'tbody tr td.views-field-title a') do |element|
      [element['href'], element.text]
    end.parent.parent.css( 'td.views-field-created') do |element, href, title|
      if m = /^(\d*)-(\d*)-(\d*)$/.match( element.text.strip)
        if t = to_date( m[1], m[2], m[3])
          result.advise( ['News'], absolutise( page.url, href), title, t)
        end
      else
        p [title, element.text]
        raise 'collect_news_posts2'
      end
    end
    result
  end

  def collect_results_posts( page, place)
    result = Elements::Body.new( place, true)
    nodes = Nodes.new( [[place.element]])
    nodes.css( 'tbody tr td.views-field-title a') do |element|
      [element['href'], element.text]
    end.parent.parent.css( 'td.views-field-field-tournament-daterange') do |element, href, title|
      if m = /(^|\D)(\d*) (\w*) (\d*)$/.match( element.text.strip)
        if t = to_date( m[4], m[3], m[2])
          result.advise( ['Events','General'], absolutise( page.url, href), title, t)
        end
      else
        p [title, element.text]
        raise 'collect_results_posts2'
      end
    end
    result
  end

  # def collect_taxonomy_posts( page, place)
  #   debug = /taxonomy\/term\/28\?page=12/ =~ page.url
  #   result = Elements::Ignore.new( place)
  #   nodes = Nodes.new( [[place.element]])
  #   nodes.css( 'div.views-row h2 a') do |element|
  #     p ['DEBUG100', element['href'], element.text] if debug
  #     [element['href'], element.text.strip]
  #   end.parent.parent.css( 'div.field__item') do |element, href, title|
  #     if m = /, (\d*) (\w*) (\d\d\d\d)$/.match( element.text.strip)
  #       if t = to_date( m[3], m[2], m[1])
  #         p ['DEBUG200', t] if debug
  #         result.advise( nil, absolutise( page.url, href), title, t)
  #       end
  #     end
  #   end
  #   result
  # end

  def define_rules
    on_element 'a', :class => 'visually-hidden' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'a' do |place|
      if %r{^https://britgo.org/taxonomy/} =~ place['href']
        Elements::Ignore.new( place)
      else
        nil
      end
    end

    on_element 'article', :ancestor => 'article' do  |place|
      place.children
    end

    on_element 'article' do  |place|
      if place.content?
        Elements::Article.new( place, 'article')
      else
        Elements::Ignore.new( place)
      end
    end

    on_element 'bold' do  |place|
      Elements::Styling.new( place, [:bold])
    end

    on_element 'button' do |place|
      if m = /^parent.location='(.*)'$/.match( place['onclick'])
        Elements::Anchor.new(place, place.absolutise(m[1]), nil)
      elsif m = /^rating_sort\(/.match( place['onclick'])
        Elements::Ignore.new( place)
      else
        nil
      end
    end

    on_element 'div', :class => '' do |place|
      place.children
    end

    on_element 'div', :class => 'attachment' do |place|
      place.children
    end

    on_element 'div', :class => 'block-system-branding-block' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'block-system-main-block' do |place|
      Elements::Article.new( place, 'article')
    end

    on_element 'div', :class => 'block-page-title-block' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'block' do |place|
      Elements::Styling.new( place, [:block])
    end

    on_element 'div', :class => 'cent' do |place|
      place.children
    end

    on_element 'div', :class => 'content' do |place|
      fabricate_description_lists( place)
    end

    on_element 'div', :class => 'clearfix' do |place|
      place.children
    end

    on_element 'div', :class => 'even' do |place|
      place.children
    end

    on_element 'div', :class => 'feed-icons' do |place|
      place.children
    end

    on_element 'div', :class => 'field__item' do |place|
      Elements::Description.new( place)
    end

    on_element 'div', :class => 'field' do |place|
      place.children
    end

    on_element 'div', :class => 'field-content' do |place|
      place.children
    end

    on_element 'div', :class => 'field__items' do |place|
      place.children
    end

    on_element 'div', :class => 'field__label' do |place|
      Elements::DescriptionTerm.new( place)
    end

    on_element 'div', :class => 'form-item' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'item-list' do |place|
      place.children
    end

    on_element 'div', :class => 'indent' do |place|
      place.children
    end

    on_element 'div', :class => 'indent2' do |place|
      place.children
    end

    on_element 'div', :class => 'last-updated' do |place|
      Elements::Ignore.new( place)
      # if m = / (\w*) (\d\d) (\d\d\d\d)/.match( place.text)
      #   Elements::Date.new( place, to_date( m[3].to_i, m[1], m[2].to_i))
      # end
    end

    on_element 'div', :class => 'links' do |place|
      place.children
    end

    on_element 'div', :class => 'node' do |place|
      place.children
    end

    on_element 'div', :class => 'node__links' do |place|
      place.children
    end

    on_element 'div', :class => 'note' do |place|
      place.children
    end

    on_element 'div', :class => 'odd' do |place|
      place.children
    end

    on_element 'div', :class => 'links' do |place|
      place.children
    end

    on_element 'div', :class => 'page' do |place|
      place.children
    end

    on_element 'div', :class => 'sidebar', :grokked => false do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'view' do |place|
      place.children
    end

    on_element 'div', :class => 'view-content' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'view-footer' do |place|
      place.children
    end

    on_element 'div', :class => 'views-col' do |place|
      place.children
    end

    on_element 'div', :class => 'views-element-container' do |place|
      place.children
    end

    on_element 'div', :class => 'view-header' do |place|
      place.children
    end

    on_element 'div', :class => 'views-field' do |place|
      place.children
    end

    on_element 'div', :class => 'views-row' do |place|
      Elements::Line.new( place)
    end

    on_element 'div', :class => 'view-taxonomy-term' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'h3' do |place|
      h3 = Elements::Heading.new( place, 3)
      h3.error? ? Elements::Group.new( place) : h3
    end

    on_element 'iframe' do |place|
      Elements::Ignore.new( place)
    end

    # on_element 'img', :class => 'floatright' do |place|
    #   Elements::Ignore.new( place)
    # end

    on_element 'li', :class => 'comment-forbidden' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'section' do  |place|
      place.children
    end

    on_element 'select', :grokked => false do |place|
      Elements::Ignore.new( place)
    end

    on_element 'span', :class => 'submitted' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'text' do |place|
      if place.text == "\n — "
        Elements::Text.new( place, '&mdash;')
      end
    end

    on_element 'text' do |place|
      if /^Coronavirus: Most Go clubs stopped meeting in person/ =~ place.text
        Elements::Ignore.new( place)
      end
    end

    on_element 'rss', :grokked => false do |place|
      Elements::Ignore.new( place)
    end

    on_page '' do |page|
      page.title= 'The British Go Association'
      page.mode=  :home

      on_element 'div', :style => /float:\s*right/ do |place|
        Elements::Ignore.new( place)
      end

      true
    end

    on_page /.*/ do |page|
      page.title= page.css( '.page-title').text.strip
      page.mode=  :article

      if m = /Newsletter.*\s(\w*) (\d\d\d\d)$/.match( page.title)
        if d = to_date( m[2], m[1], 1)
          page.date= d
          page.mode= :post
        end
      end

      ignores = [
          # Forms for tournaments membership etc
          /-entries\.html$/,
          /-form(\.html|)$/,

          # Unloved and broken
          /\/book\/export/,
          /\/clubs\/index/,
          /\/clubs\/list/,
          /\/clubs\/_request/,
          /\/tournaments\/current/,

          # Forms
          'https://britgo.org/form/transfer-your-membership',
          'https://britgo.org/user/login',
          'https://britgo.org/tournaments/britishopen/entryform',
          'https://britgo.org/user/password',
          'https://britgo.org/eygc2014/enterbgc',

          # Maps
          /\/clubs\/map/,
          /\/clubs\/region/,

          # Applets
          'https://britgo.org/capturego/play',

          # HTML errors and oddities
          'https://britgo.org/bakabanrev',
          'https://britgo.org/bgj/06014.html',
          'https://britgo.org/bgj/06026.html',
          'https://britgo.org/bgj/06320.html',
          'https://britgo.org/reviews/mygofriend',
          'https://britgo.org/softwarereviews',
          'https://britgo.org/tournaments/history07.html',
          'https://britgo.org/tournaments/history08.html',
          'https://britgo.org/tournaments/history09.html',
          'https://britgo.org/tournaments/history10.html',
          'https://britgo.org/tournaments/history11.html',

          # Index pages
          'https://britgo.org/junior/youthgonews'
      ]

      ignored = false
      ignores.each do |re|
        if re.is_a?( String)
          ignored = true if re == page.url
        else
          ignored = true if re =~ page.url
        end
      end

      if ignored
        on_element 'body', :grokked => false do |place|
          Elements::Body.new( place, true)
        end
      end

      false
    end

    on_page 'bgj/bgj108' do |page|
      on_element 'td' do |place|
        Elements::Paragraph.new( place)
      end
      false
    end

    on_page /bgj\/(bgj|issue)\d+/ do |page|
      seasons = 'Summer|Autumn|Winter|Spring|January|February|March|April|May|June|July|August|September|October|November|December'

      on_element 'h1', :class => 'page-title' do |place|
        if m = /(?:#{seasons}) (\d\d\d\d)/.match( place.text)
          year = (m[1].to_i / 5) * 5
          page.index = ['British Go Journal', "#{year}-#{year+4}"]
        end
        nil
      end

      on_element 'h2' do |place|
        if m = /(?:#{seasons}) (\d\d\d\d)/.match( place.text)
          year = (m[1].to_i / 5) * 5
          page.index = ['British Go Journal', "#{year}-#{year+4}"]
        end
        nil
      end
    end

    on_page 'junior/champs' do |page|
      on_element 'font' do |place|
        Elements::Group.new( place)
      end
      false
    end

    on_page /^allnews($|\?)/ do |page|
      on_element 'body', :grokked => false do |place|
        collect_news_posts( page, place) # Elements::Ignore.new( place)
      end

      true
    end

    on_page /^results_xxxx($|\?)/ do |page|
      on_element 'body', :grokked => false do |place|
        collect_results_posts( page, place) # Elements::Ignore.new( place)
      end

      true
    end

    on_page %r{^(taxonomy/)} do |page|
      on_element 'body', :grokked => false do |place|
        Elements::Body.new( place, true)
      end
      false
    end

    on_page %r{^(news$|results/12months$)} do |page|
      on_element 'div', :class => 'block-system-main-block' do |place|
        Elements::Ignore.new( place)
      end
      false
    end

    on_page %r{(^|\D)\d\d\d\d(\D|$)} do |page|
      unless /^(bchamp\/chrules|bgj|node|results|comment|reps|review)(\/|$)/ =~ page.relative_url
        m = /(^|\D)(\d\d\d\d)(\D|$)/.match( page.relative_url)
        page.date=  Time.new( m[2].to_i)
        page.mode=  :post
        page.index= ['News'] unless ! page.index.empty?
      end
      false
    end

    on_page /(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\d\d$/i do |page|
      unless /^(bgj|node|results|comment|review)$/ =~ page.relative_path[0]
        if t = to_date( page.relative_path[-1][-2..-1], page.relative_path[-1][-5..-3], 1)
          page.date= t
          page.mode= :post
        end
      end
      false
    end

    on_page %r{^events/firstmsfestival} do |page|
      page.date= Time.new( 2011, 11, 17)
      page.mode= :post
      false
    end

    on_page %r{^(junior|news)/} do |page|
      if m = %r{^\w+, (\d\d)/(\d\d)/(\d\d\d\d)( |$)}.match( page.css( 'span.submitted').text.strip)
        page.date = to_date( m[3], m[2], m[1])
        page.mode= :post
      end

      if m = %r{^\w+, (\d\d) (\w\w\w) (\d\d\d\d)( |$)}.match( page.css( 'span.submitted').text.strip)
        page.date = to_date( m[3], m[2], m[1])
        page.mode= :post
      end

      page.css( 'div.field__item').each do |element|
        # if /results\/2017\/mso13/ =~ page.url
        #   p [ 'DEBUG2', element.text.strip]
        # end
        if m = %r{, (\d{1,2}) (\w\w\w) (\d\d\d\d)$}.match( element.text)
          page.date = to_date( m[3], m[2], m[1])
          page.mode= :post
        end

        false
      end

      false
      # if m = %r{, (\d\d) (\w\w\w) (\d\d\d\d)$}.match( page.css( 'div.field__item').text.strip)
      #   page.date = to_date( m[3], m[2], m[1])
      #   page.mode= :post
      # end
      #
    end

    on_page /.*/ do |page|
      map = {
          /\?page=\d/                      => [],
          /^bchamp\/(book|chrules)/        => ['Admin','British Championship'],
          /^bchamp\/(history|matthew)/     => ['History','British Championship'],
          /^bchamp\/\d\d\d\d/              => ['Events','British Championship'],
          /^bchamp\/qualifiers\d\d\d\d/    => ['Events','British Championship'],
          /^bchamp\/qualifying\.html$/     => ['Admin', "Qualifying"],
          /^bchamp\//                      => ['Tournaments','*'],
          /^bgj\/0/                        => [],
          /^bgj\/glossary.html/            => ['Admin', "British Go Journal"],
          /^bgj\/guidelines.html/          => ['Admin', "British Go Journal"],
          /^bgj\/history\//                => ['History', "British Go Journal"],
          /^bgj\/index\/alph/              => [],
          /^bgj\/index\/auth/              => [],
          /^bgj\/index\/chron/             => [],
          /^bgj\/index\/subj/              => [],
          /^bgj\//                         => ['British Go Journal','General'],
          /^book\/londonopen/              => ['Admin', "London Open"],
          /^booklist\//                    => 'Book list',
          /^books\//                       => 'Book list',
          /^club(|s)\//                    => ['Clubs', '*'],
          /^committee\/clubs\//            => ['Admin','Clubs'],
          /^committee\//                   => ['Admin','Council'],
          /^council\//                     => ['Admin','Council'],
          /^education\//                   => 'Teaching',
          /^ejournal\/\d/                  => [],
          /^ejournal\/index/               => ['History','Newsletters'],
          /^events\/euroteams\d\d\d\d/     => ['Events','Euroteams'],
          /^events\/euroteams/             => ['Tournaments','*'],
          /^events\/goweek/                => ['Tournaments','*'],
          /^events\/wmsg/                  => ['Events','World Mind Sports'],
          /^events\//                      => ['Events','General'],
          /^eygc2014/                      => ['Events','EYGC2014'],
          /^general\//                     => 'General',
          /^gopcres\//                     => 'General',
          /^history\/.*\d\d\d\d.*/         => ['History','By year'],
          /^history\//                     => ['History','General'],
          /^hof\//                         => ['History','Hall of Fame'],
          /^junior\/events\/.*\d\d\d\d/    => ['Events','Junior'],
          /^junior\/.*\d\d\d\d/            => ['Results','Junior'],
          /^junior\//                      => 'Youth',
          /^learngoweek2014/               => ['Events','General'],
          /^learn/                         => 'Teaching',
          /^membership\//                  => 'Membership',
          /^news\/enews/                   => ['History','News'],
          /^news\//                        => 'News',
          /^newsletter\//                  => 'Newsletters',
          /^node/                          => [],
          /^obits\//                       => 'Obituaries',
          /^organisers\//                  => ['Admin','Organisers'],
          /^pairgo\/photos\d\d\d\d/        => ['Events','PairGo'],
          /^people\//                      => 'People',
          /^policy/                        => ['Admin','Policies'],
          /^positions\//                   => ['Admin','Positions'],
          /^reps\//                        => ['Tournaments','*'],
          /^resources\//                   => ['Admin','Resources'],
          /^review\//                      => 'Reviews',
          /^rules/                         => ['Admin','Rules'],
          /^teaching\//                    => 'Teaching',
          /^tournaments\/history/          => ['History','Tournaments'],
          /^tournaments\/logc\/.*\d\d\d\d/ => ['Events','London'],
          /^tournaments.*\d\d\d\d/         => ['Events','General'],
          /^tournaments\//                 => ['Tournaments','*'],
          /^wmsg/                          => ['Events','World Mind Sports'],
          /^youthnews\/current/            => 'Youth',
          /^youthnews/                     => 'News',
          /^youth/                         => 'Youth'
      }

      map.each_pair do |re, index|
        if re =~ page.relative_url
          page.index = index.is_a?( Array) ? index : [index]
          break
        end
      end

      false
    end

    on_page /^results\/\d\d\d\d\// do |page|
      year   = page.relative_path[1].to_i
      decade = (year / 10) * 10

      on_element 'div', :class => 'field__item' do |place|
        if m = /, (\d*) (\w*) (\d\d\d\d)$/.match( place.text.strip)
          if t = to_date( m[3], m[2], m[1])
            page.date  = t
            page.index = ['Results', decade.to_s + ' - ' + (decade+9).to_s]
            page.mode  = :post
          end
        end
        nil
      end

      false
    end

    on_page 'tournaments' do |page|
      on_element 'div', :class => 'region-sidebar-first' do |place|
        Elements::Ignore.new( place)
      end

      on_element 'div', :class => 'region-sidebar-second' do |place|
        Elements::Article.new( place, 'sidebar')
      end

      on_element 'div', :class => 'sidebar', :grokked => false do |place|
        place.children
      end

      false
    end

    on_page /^(wmsg|events\/wmsg)/ do |page|
      if page.mode == :article
        page.mode = :post
        page.date = Time.new( 2008)
      end
      false
    end

    super
  end

  def fabricate_description_lists( place)
    final, interim, do_dl = [], [], false
    # if /londonopen/ =~ place.page.url
    #   place.children.each do |child|
    #     puts "...  #{child.class.to_s}: #{child.text}"
    #   end
    #   puts "\n"
    # end

    place.children.each do |child|
      if child.is_a?( Elements::Description)
        interim << child
        do_dl = true
      elsif child.is_a?( Elements::DescriptionTerm)
        interim << child
        do_dl = true
      elsif child.content?
        if do_dl
          final << Elements::DescriptionList.new( Place.new( place.page, place.element, interim))
        else
          interim.each {|boring| final << boring}
        end
        final << child
        interim, do_dl = [], false
      else
        interim << child
      end
    end

    if do_dl
      final << Elements::DescriptionList.new( Place.new( place.page, place.element, interim))
    else
      final = final + interim
    end

    if place.debug?
      puts "\n... fabricate_description_lists"
      final.each do |child|
        puts "...  #{child.class.to_s}: #{child.text[0..29].gsub( /\s/, ' ').strip}"
      end
    end

    final
  end

  def get_latest_date( place)
    date, text = nil, place.text

    text.scan( %r{\W(\d\d)/(\d\d)/(\d\d)\W}) do |found|
      date = latest_date( date, to_date( found[2], found[1], found[0]))
    end

    text.scan( %r{\W(\d+)(?:th|nd|st|rd|) (\w+) (\d\d\d\d)\W}) do |found|
      begin
       date = latest_date( date, to_date( found[2], found[1], found[0]))
      rescue
        p [place.url, found]
        raise
      end
    end

    date
  end

  def latest_date( d1, d2)
    return d2 if d1.nil?
    return d1 if d2.nil?
    (d2 > d1) ? d2 : d1
  end

  def page_param_only( url)
    url = url.split('?')
    if url[1]
      page_num = 0
      url[1].split('&').each do |param|
        if m = /^page=(\d+)$/.match( param)
          page_num = m[1].to_i
        end
      end

      if page_num > 0
        "#{url[0]}?page=#{page_num}"
      else
        url[0]
      end
    else
      url[0]
    end
  end

  def to_date( year, month, day)
    #p ['to_date1', year, month, day]
    year = year.to_i
    if year < 100
      if year < 40
        year += 2000
      else
        year += 1900
      end
    end
    day  = day.to_i
    return nil if (day < 1) || (day > 31)

    if /^\d+$/ =~ month
      month = month.to_i
      return nil if (month < 1) || (month > 12)
    else
      months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec']
      return nil unless months.include?( month[0..2].downcase)
      month = months.index( month[0..2].downcase) + 1
    end
    #p ['to_date2', year, month, day]
    Time.new( year, month, day)
  end
end

class BGA < Site
  def initialize( config)
    super
    taxonomy 'Section', 'Sections'
    @post_dates = {}
  end

  def absolutise( page_url, url)
    super( page_url, page_param_only( url))
  end

  def define_rules
    on_element 'a', :class => 'visually-hidden' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'button' do |place|
      if m = /^parent.location='(.*)'$/.match( place['onclick'])
        Elements::Anchor.new( place, place.absolutise( m[1]), nil)
      else
        nil
      end
    end

    on_element 'div', :class => '' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'attachment' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'block-system-branding-block' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'block-system-main-block' do |place|
      Elements::Article.new( place).set_title( place.title).set_date( place.date)
      #     place.date ? place.date : get_latest_date( place)
      # )
    end

    on_element 'div', :class => 'block-page-title-block' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'block' do |place|
      Elements::Styling.new( place, [:block])
    end

    on_element 'div', :class => 'clearfix' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'even' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'feed-icons' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'field' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'field-content' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'field__item' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'field__items' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'field__label' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'form-item' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'item-list' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'indent' do |place|
      Elements::Styling.new( place, [:indent])
    end

    on_element 'div', :class => 'last-updated' do |place|
      Elements::Ignore.new( place)
      # if m = / (\w*) (\d\d) (\d\d\d\d)/.match( place.text)
      #   Elements::Date.new( place, to_date( m[3].to_i, m[1], m[2].to_i))
      # end
    end

    on_element 'div', :class => 'links' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'node' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'node__links' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'odd' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'links' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'page' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'sidebar', :grokked => false do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'view' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'view-content' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'view-footer' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'views-col' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'views-element-container' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'view-header' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'views-field' do |place|
      Elements::Group.new( place)
    end

    on_element 'div', :class => 'views-row' do |place|
      Elements::Group.new( place)
      Elements::Styling.new( place, [:row])
    end

    on_element 'iframe' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'section' do  |place|
      Elements::Group.new( place)
    end

    on_element 'select', :grokked => false do |place|
      Elements::Ignore.new( place)
    end

    on_element 'text' do |place|
      if place.text == "\n ??? "
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

    on_page /^(allnews|results_xxxx)($|\?)/ do |page|
      on_element 'body', :grokked => false do |place|
        Elements::Ignore.new( place)
      end

      true
    end

    on_page %r{^(taxonomy/|news$|results/12months$)} do |page|
      on_element 'div', :class => 'block-system-main-block' do |place|
        Elements::Ignore.new( place)
      end
    end

    on_page %r{^\w*/\w*\d\d\d\d(|$)} do |page|
      unless /^(bgj|node)$/ =~ page.relative_path[0]
        page.date= Time.new( page.relative_path[1][-4..-1].to_i)
        page.mode= :post
      end
      false
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

      if date = @post_dates[page.url]
        page.date= date
        page.mode= :post
      end

      false
    end

    on_page %r{^(junior|news|results)/} do |page|
      if m = %r{^\w+, (\d\d)/(\d\d)/(\d\d\d\d)( |$)}.match( page.css( 'span.submitted').text.strip)
        page.date = to_date( m[3], m[2], m[1])
        page.mode= :post
      end

      if m = %r{^\w+, (\d\d) (\w\w\w) (\d\d\d\d)( |$)}.match( page.css( 'span.submitted').text.strip)
        page.date = to_date( m[3], m[2], m[1])
        page.mode= :post
      end

      # if /results\/2017\/mso13/ =~ page.url
      #   p [ 'DEBUG1', page.css( 'div.field__item').text.strip]
      # end

      page.css( 'div.field__item').each do |element|
        # if /results\/2017\/mso13/ =~ page.url
        #   p [ 'DEBUG2', element.text.strip]
        # end
        if m = %r{, (\d{1,2}) (\w\w\w) (\d\d\d\d)$}.match( element.text)
          page.date = to_date( m[3], m[2], m[1])
          page.mode= :post
        end
      end

      false
      # if m = %r{, (\d\d) (\w\w\w) (\d\d\d\d)$}.match( page.css( 'div.field__item').text.strip)
      #   page.date = to_date( m[3], m[2], m[1])
      #   page.mode= :post
      # end
      #
    end

    on_page %r{^(\w*)(/|$)} do |page|
      section = {
          'bchamp'      => 'British Championship',
          'bgj'         => 'British Go Journal',
          'booklist'    => 'Book list',
          'books'       => 'Book list',
          'club'        => 'Clubs',
          'clubs'       => 'Clubs',
          'council'     => 'Council',
          'education'   => 'Teaching',
          'events'      => 'Events',
          'eygc2014'    => 'European Youth Go Congress 2014',
          'general'     => 'General',
          'gopcres'     => 'Playing online',
          'history'     => 'History',
          'hof'         => 'Hall of Fame',
          'junior'      => 'Youth',
          'membership'  => 'Membership',
          'news'        => 'News',
          'newsletter'  => 'Newsletters',
          'obits'       => 'Obituaries',
          'organisers'  => 'Organisers',
          'people'      => 'People',
          'positions'   => 'Positions',
          'reps'        => 'Reports',
          'resources'   => 'Resources',
          'results'     => 'Results',
          'review'      => 'Reviews',
          'teaching'    => 'Teaching',
          'tournaments' => 'Events',
          'youth'       => 'Youth'
      }[page.relative_path[0]]
      page.add_tag( 'Section', section) if section
      false
    end

    on_page 'committee/clubs' do |page|
      page.add_tag( 'Section', 'Clubs')
      false
    end

    super
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

  def preparse( url, page)
    nodes = page_to_nodes( page)

    nodes.css( 'td.views-field-title a') do |node|
      [absolutise( url, node['href'])]
    end.parent.parent.css( 'td.views-field-created') do |node1, href|
      if m = /(\d\d\d\d)-(\d\d)-(\d\d)/.match( node1.text)
        @post_dates[href] = to_date( m[1], m[2], m[3])
      end
      false
    end

    nodes.css( 'td.views-field-title a') do |node|
      [absolutise( url, node['href'])]
    end.parent.parent.css( 'td.views-field-field-tournament-daterange') do |node1, href|
      if m = /(\d+) (\w*) (\d\d\d\d)/.match( node1.text)
        @post_dates[href] = to_date( m[3], m[2], m[1])
      end
      false
    end
  end

  def redirect( url, target)
    super
    if @post_dates[url]
      @post_dates[target] = @post_dates[url]
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
      months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
      return nil unless months.include?( month[0..2])
      month = months.index( month[0..2]) + 1
    end
    #p ['to_date2', year, month, day]
    Time.new( year, month, day)
  end
end

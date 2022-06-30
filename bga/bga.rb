class BGA < Site
  def initialize( config)
    super
    taxonomy 'Section', 'Sections'
    @post_dates = {}
  end

  def define_rules
    on_element 'a', :class => 'visually-hidden' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'button' do |place|
      if m = /^parent.location='(.*)'$/.match( place['onclick'])
        Elements::Anchor.new( place, place.absolutise( m[1]))
      else
        nil
      end
    end

    on_element 'div', :class => '' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'block-system-branding-block' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'block-system-main-block' do |place|
      Elements::Article.new( place).set_title( place.title).set_date( get_latest_date( place))
    end

    on_element 'div', :class => 'block-page-title-block' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'block' do |place|
      Elements::Styling.new( place, [:block])
    end

    on_element 'div', :class => 'clearfix' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'feed-icons' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'field' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'field-content' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'field__item' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'field__items' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'field__label' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'form-item' do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'item-list' do |place|
      Elements::Styling.new( place, [])
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
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'node' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'node__links' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'sidebar', :grokked => false do |place|
      Elements::Ignore.new( place)
    end

    on_element 'div', :class => 'view' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'view-content' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'view-footer' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'views-element-container' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'view-header' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'views-field' do |place|
      Elements::Styling.new( place, [])
    end

    on_element 'div', :class => 'views-row' do |place|
      Elements::Styling.new( place, [:row])
    end

    # on 'span', :class => 'submitted' do
    #   p children[1].text
    #   nil
    # end

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
      page.mode=  :article
      true
    end

    on_page /^(allnews|results_xxxx)($|\?)/ do |page|
      on_element 'a' do  |place|
        if place['href']
          Elements::Anchor.new( place, place.absolutise( page_param_only(place['href'])))
        else
          Elements::Text.new( place, '')
        end
      end

      on_element 'body', :grokked => false do |place|
        Elements::Ignore.new( place)
      end

      true
    end

    on_page /.*/ do |page|
      page.title= page.css( '.page-title').text.strip
      page.mode=  :article
      false
    end

    on_page %r{^(\w*)(/|$)} do |page|
      section = {
          'bchamp'      => 'British Championship',
          'bgj'         => 'British Go Journal',
          'booklist'    => 'Book list',
          'clubs'       => 'Clubs',
          'council'     => 'Council',
          'education'   => 'Teaching',
          'events'      => 'Events',
          'gopcres'     => 'Playing online',
          'history'     => 'History',
          'hof'         => 'Hall of Fame',
          'junior'      => 'Youth',
          'membership'  => 'Membership',
          'news'        => 'News',
          'newsletter'  => 'Newsletters',
          'obits'       => 'Obituaries',
          'reps'        => 'Reports',
          'resources'   => 'Resources',
          'results'     => 'Results',
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

    on_page 'bchamp/index.html' do |page|
      page.date= Time.now
      page.mode= :post
      false
    end

    on_page %r{^\w*/\w*\d\d\d\d$} do |page|
      page.date= Time.at( page.relative_path[-1][-4..-1].to_i)
      page.mode= :post
      false
    end

    on_page /.*/ do |page|
      if date = @post_dates[page.url]
        page.date= date
        page.mode= :post
      end
      false
    end

    super
  end

  def get_latest_date( place)
    date, text = nil, place.text

    text.scan( %r{\W(\d\d)/(\d\d)/(\d\d)\W}) do |found|
      date = latest_date( date, to_date( '20' + found[2], found[1], found[0]))
    end

    text.scan( %r{\W(\d+)(?:th|nd|st|rd) (\w+) (\d\d\d\d)\W}) do |found|
       date = latest_date( date, to_date( found[2], found[1], found[0]))
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
      [Site.absolutise( @config['root_url'], url, node['href'])]
    end.parent.parent.css( 'td.views-field-created') do |node1, href|
      if m = /(\d\d\d\d)-(\d\d)-(\d\d)/.match( node1.text)
        @post_dates[href] = to_date( m[1], m[2], m[3])
      end
      false
    end

    nodes.css( 'td.views-field-title a') do |node|
      [Site.absolutise( @config['root_url'], url, node['href'])]
    end.parent.parent.css( 'td.views-field-field-tournament-daterange') do |node1, href|
      if m = /(\d+) (\w*) (\d\d\d\d)/.match( node1.text)
        @post_dates[href] = to_date( m[3], m[2], m[1])
      end
      false
    end
  end

  def to_date( year, month, day)
    #p ['to_date1', year, month, day]
    year = year.to_i
    day  = day.to_i
    if /^\d+$/ =~ month
      month = month.to_i
    else
      months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
      return nil unless months.include?( month[0..2])
      month = months.index( month[0..2]) + 1
    end
    #p ['to_date2', year, month, day]
    Time.new( year, month, day)
  end
end

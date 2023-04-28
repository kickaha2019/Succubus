require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'
require 'nokogiri'

class DanCertificates
  EGD='https://europeangodatabase.eu/EGD/'

  def initialize( args)
    @dir     = nil
    @country = 'UK'
    @refresh = true

    args.each do |arg|
      if m = /^dir=(.*)$/.match( arg)
        @dir     = m[1]
      elsif m = /^refresh=(.*)$/.match( arg)
        @refresh = (m[1].downcase == 'true')
      elsif m = /^country=(.*)$/.match( arg)
        @country = m[1]
      else
        raise "Unexpected argument: #{arg}"
      end
    end
    raise 'No working directory specified' unless @dir
  end

  def cache_versions
    versions = []
    Dir.entries( @dir).each do |f|
      if m = /^(\d+)\.yaml$/.match( f)
        versions << m[1].to_i
      end
    end
    versions.sort
  end

  def extract_table( doc, extract_columns)
    found_table = false

    doc.css( 'table').each do |table|
      next unless table['bordercolor'] == '#396B95'
      columns = {}
      headers = table.css( 'th').collect do |cell|
        cell.content.strip.gsub( '&nbsp', '')
      end

      headers.each_index do |i|
         columns[headers[i]] = i
      end

      if extract_columns.inject( true) {|r,e| r & columns[e]}
        found_table = true

        table.css( 'tr').each do |row|
          values = []
          row.css( 'td.plain').each do |cell|
            values << cell.content
          end

          if values.size >= extract_columns.size
            yield( * extract_columns.collect {|c| values[columns[c]]})
          end
        end
      end
    end

    unless found_table
      raise "No table found with columns: #{extract_columns.join( ' / ')}"
    end
  end

  def get_player_history(pin)
    html    = http_get( "#{EGD}Player_Card.php?&key=#{pin}")
    html.value
    doc     = Nokogiri::HTML( html.body).root
    history = []

    gor     = [0,0]
    columns = ['Tournament Code','Date','GoR before_>_after']
    extract_table( doc, columns) do |tcode, date, gor_change|
      gor = gor_change.split(' --> ')
      history << [tcode,date,gor[1].to_i]
    end

    history << ['','',gor[0]]
    history
  end

  def get_players_page( from)
    args = ['ricerca=1',
            "country_code=#{@country}",
            "viewStart=viewStart=#{from}",
            'orderBy=orderBy=Last_Name',
            'orderDir=orderDir=ASC']

    html = http_get( "#{EGD}Find_Player.php?" + args.join('&'))
    html.value
    # File.open( "#{@dir}/temp.html", 'w') {|io| io.print html.body}
    Nokogiri::HTML( html.body).root
  end

  def http_get( url)
    sleep 10
    uri = URI.parse( url)

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Accept']          = 'text/html,application/xhtml+xml'
    request['Accept-Language'] = 'en-gb'
    request['User-Agent']      = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'

    use_ssl     = uri.scheme == 'https'
    verify_mode = OpenSSL::SSL::VERIFY_NONE

    Net::HTTP.start( uri.hostname, uri.port, :use_ssl => use_ssl, :verify_mode => verify_mode) {|http|
      http.request( request)
    }
  end

  def load_cached_data
    versions = cache_versions
    if versions.size > 0
      @players = YAML.load( IO.read( "#{@dir}/#{versions[0]}.yaml"))
    else
      @players = {}
    end
  end

  def refresh_cached_data
    if @refresh
      from = 0
      while from >= 0
        doc = get_players_page(from)
        from = -1
        doc.css( 'a').each do |link|
          next unless link.content == 'Next'
          if m = /viewStart=(\d+)&/.match( link['href'])
            from = m[1].to_i
          end
        end

        columns = ['Pin Player','First Name','Last Name','Club','Total tournaments']
        extract_table( doc, columns) do |pin, first_name, last_name, club, tournaments|
          pin         = pin.to_i
          tournaments = tournaments.to_i
          unless (tournaments < 10) || (@players[pin] && (@players[pin]['tournaments'] == tournaments))
            puts "... Fetching player history for #{first_name} #{last_name}"
            @players[pin] = {'first_name'  => first_name,
                             'last_name'   => last_name,
                             'club'        => club,
                             'tournaments' => tournaments,
                             'history'     => get_player_history(pin)}
          end
        end

        File.open( "#{@dir}/#{Time.now.to_i}.yaml", 'w') do |io|
          io.print @players.to_yaml
        end

        cache_versions[0..-2].each do |ts|
          File.delete( "#{@dir}/#{ts}.yaml")
        end
      end
    end
  end
end

dc = DanCertificates.new( ARGV)
dc.load_cached_data
dc.refresh_cached_data
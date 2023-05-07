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
    @output  = nil

    args.each do |arg|
      if m = /^dir=(.*)$/.match( arg)
        @dir     = m[1]
      elsif m = /^refresh=(.*)$/.match( arg)
        @refresh = (/^(Y|true|yes)$/i =~ m[1])
      elsif m = /^country=(.*)$/.match( arg)
        @country = m[1]
      elsif m = /^output=(.*)$/.match( arg)
        @output  = m[1]
      else
        raise "Unexpected argument: #{arg}"
      end
    end

    raise 'No working directory specified' unless @dir
    @output = "#{@dir}/report.csv" unless @output
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

  def derive_dan_grades
    @players.each_value do |player|
      grade, date, lowest = 0, '', 100000
      (9..(player['history'].size-2)).each do |i|
        r   = player['history'][-2-i]
        r10 = player['history'][-2-i+10]

        lowest = r10['rating'] if r10['rating'] < lowest
        if r['rating'] >= lowest
          g = (r['rating'] - 2000) / 100
          if g > grade
            grade, date = g, r['date']
          end
        end
      end

      player['grade'] = grade
      player['when']  = date
    end
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

  def generate_report
    File.open( @output, 'w') do |io|
      io.puts "Pin,First name,Last name,Club,Grade,Date"
      dan_players = @players.values.select {|player| player['grade'] > 0}

      dan_players.sort_by! {|player| player['last_name'] + 'ZZZ' + player['first_name']}

      dan_players.each do |player|
        io.puts <<PLAYER
#{player['pin']},#{player['first_name']},#{player['last_name']},#{player['club']},#{player['grade']},#{player['when']}
PLAYER
      end
    end
  end

  def get_next( doc)
    doc.css( 'a').each do |link|
      next unless link.content == 'Next'
      if m = /viewStart=(\d+)&/.match( link['href'])
        return m[1].to_i
      end
    end
    -1
  end

  def get_player_history(pin)
    from, last_from = 0, -1
    history = []
    gor     = [0,0]
    columns = ['Tournament Code','Date','GoR before_>_after']

    while from > last_from
      last_from = from

      args = ["key=#{pin}",
              "viewStart=viewStart=#{from}",
              'orderBy=orderBy=Tournament_Date,Tournament_Code',
              'orderDir=orderDir=DESC']

      html = http_post( "#{EGD}Player_Card.php", args.join('&'))
      html.value
      #File.open( "#{@dir}/temp1.html", 'w') {|io| io.print html.body}
      doc  = Nokogiri::HTML( html.body).root
      from = get_next( doc)

      extract_table( doc, columns) do |tcode, date, gor_change|
        gor = gor_change.split(' --> ')
        history << {'tournament' => tcode,
                    'date'       => date,
                    'rating'     => gor[1].to_i}
      end
    end

    history << {'tournament' => '', 'date' => '1970-01-01', 'rating' => gor[0].to_i}
    history
  end

  # https://europeangodatabase.eu/EGD/Find_Player.php?ricerca=1&country_code=UK&viewStart=viewStart=200&orderBy=orderBy=Last_Name&orderDir=orderDir=ASC
  # curl -X POST -d 'ricerca=1&country_code=UK&viewStart=viewStart=200&orderBy=orderBy=Last_Name&orderDir=orderDir=ASC' https://europeangodatabase.eu/EGD/Find_Player.php
  def get_players_page( from)
    args = ['ricerca=1',
            "country_code=#{@country}",
            "viewStart=viewStart=#{from}",
            'orderBy=orderBy=Last_Name',
            'orderDir=orderDir=ASC']

    puts "... Listing players from #{from}"
    html = http_post( "#{EGD}Find_Player.php", args.join('&'))
    html.value
    #File.open( "#{@dir}/temp.html", 'w') {|io| io.print html.body}
    Nokogiri::HTML( html.body).root
  end

  def http_get( url)
    sleep 30
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

  def http_post( url, data)
    # p ['http_post', url, data]
    # raise 'Dev'
    sleep 10
    uri = URI.parse( url)

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body               = data
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
      # puts "*** Remove this code"
      # @players.each_pair do |pin, info|
      #   info['pin'] = pin
      #   info['history'].each do |rec|
      #     rec['rating'] = rec['rating'].to_i
      #   end
      # end
    else
      @players = {}
    end
  end

  def refresh_cached_data
    if @refresh
      from      = 0
      last_from = -1

      while from > last_from
        doc       = get_players_page(from)
        last_from = from
        from      = get_next( doc)

        columns = ['Pin Player','First Name','Last Name','Club','Total tournaments']
        extract_table( doc, columns) do |pin, first_name, last_name, club, tournaments|
          pin         = pin.to_i
          tournaments = tournaments.to_i

          if (tournaments >= 10) && (@players[pin].nil? || (@players[pin]['tournaments'] != tournaments))
            puts "... Fetching player history for #{first_name} #{last_name}"
            @players[pin] = {'pin'         => pin,
                             'first_name'  => first_name,
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
dc.derive_dan_grades
dc.generate_report

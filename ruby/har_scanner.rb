require 'json'

class HarScanner
  STATES = ['blocked','dns','connect','ssl','send','wait','receive']

  def initialize( path)
    @har = JSON.parse( IO.read( path))
  end

  def find_receives
    receives   = []
    page_start = to_date( @har['log']['pages'][0]['startedDateTime'])

    @har['log']['entries'].each do |entry|
      t = 1000 * (to_date( entry['startedDateTime']) - page_start)
      timings = entry['timings']

      STATES.each do |state|
        unless timings[state].nil? || (timings[state] <= 0)
          if state == 'receive'
            receives << [t, timings[state], entry['request']['url']]
          end
          t += timings[state]
        end
      end
    end

    receives.sort_by do |receive|
      receive[0]
    end
  end

  def report_date( text)
    to_date( text).to_s
  end

  def report_entries( path)
    File.open( path, 'w') do |io|
      io.print "Path\tStart time\tTook"
      STATES.each {|state| io.print "\t#{state}"}
      io.puts
      @har['log']['entries'].each do |entry|
        report_entry( entry['request']['url'],
                      entry['startedDateTime'],
                      entry['time'],
                      entry['timings'],
                      io)
      end
    end
  end

  def report_entry( url, start, took, timings, io)
    io.print "#{url}\t#{report_date(start)}\t#{took}"
    STATES.each do |state|
      if timings[state].nil? || (timings[state] < 0)
        io.print "\t0"
      else
        io.print "\t#{timings[state]}"
      end
    end
    io.puts
  end

  def report_fetches(re)
    count, size = 0, 0
    @har['log']['entries'].each do |entry|
      if re =~ entry['request']['url']
        count += 1
        size  += entry['response']['content']['size']
      end
    end

    "#{count} fetches, #{size} bytes"
  end

  def report_receiving
    receives = find_receives

    receiving, t = 0, 0
    receives.each do |receive|
      rfrom, rfor = receive[0], receive[1]
      if rfrom + rfor < t
        #p [receive[2], rfrom, t, receiving]
        next
      end

      if t > rfrom
        rfor = rfor - (t - rfrom)
      else
        t = rfrom
      end

      receiving += rfor
      t = t + rfor
      #p [receive[2], rfrom, t, receiving]
    end

    page0 = @har['log']['pages'][0]
    time0 = page0['pageTimings']
    "%d ms, %0.2f%%" % [receiving, (100.0 * receiving) / (time0['onContentLoad'] + time0['onLoad'])]
  end

  def report_stats( path)
    page0 = @har['log']['pages'][0]
    time0 = page0['pageTimings']

    File.open( path, 'w') do |io|
      io.puts "Date:        #{report_date( page0['startedDateTime'])}"
      io.puts "Page:        #{page0['title']}"
      io.puts "Took:        #{report_time( time0['onContentLoad'] + time0['onLoad'])}"
      io.puts "Files:       #{report_fetches(/.*/)}"
      io.puts "CSS files:   #{report_fetches(/\.css($|\?)/)}"
      io.puts "JS files:    #{report_fetches(/\.js($|\?)/)}"
      io.puts "Image files: #{report_fetches(/\.(jpg|jpeg|gif|png|webp)($|\?)/i)}"
      io.puts "Receiving:   #{report_receiving}"
    end
  end

  def report_time( t)
    "%d ms" % [t.to_i]
  end

  def to_date( text)
    if m = /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):([0-9\.]+)Z$/.match( text)
      Time.new( m[1].to_i, m[2].to_i, m[3].to_i, m[4].to_i, m[5].to_i, m[6].to_f)
    else
      raise "Bad date time #{text}"
    end
  end
end

hs = HarScanner.new( ARGV[0])
hs.report_entries( ARGV[1])
hs.report_stats( ARGV[2])

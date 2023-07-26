require 'json'

class HarScanner
  STATES = ['blocked','dns','connect','ssl','send','wait','receive']

  def initialize( path)
    @har = JSON.parse( IO.read( path))
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

  def report_stats( path)
    page0 = @har['log']['pages'][0]
    time0 = page0['pageTimings']

    File.open( path, 'w') do |io|
      io.puts "Date:        #{report_date( page0['startedDateTime'])}"
      io.puts "Page:        #{page0['title']}"
      io.puts "Took:        #{report_time( time0['onContentLoad'] + time0['onLoad'])}"
      io.puts "Files:       #{report_fetches(/.*/)}"
      io.puts "CSS files:   #{report_fetches(/\.css$/)}"
      io.puts "JS files:    #{report_fetches(/\.js$/)}"
      io.puts "Image files: #{report_fetches(/\.(jpg|jpeg|gif|png|webp)$/i)}"
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

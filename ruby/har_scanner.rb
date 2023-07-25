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

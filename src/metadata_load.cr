require "option_parser"
require "placeos"
require "uri"

@[Flags]
enum Mode
  Read
  Write
end

place_domain = ""
api_key = ""
load = 5
mode = Mode::Read | Mode::Write

# Command line options
OptionParser.parse do |parser|
  parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"

  parser.on("-u URI", "--uri=URI", "the domain we are going to hit") do |domain|
    place_domain = URI.parse(domain).hostname.not_nil!
  end

  parser.on("-a APIKEY", "--apikey=APIKEY", "the api key to use for the requests") do |key|
    api_key = key
  end

  parser.on("-l LOAD", "--load=LOAD", "how many concurrent requests we want to make") do |l|
    load = l.to_i
  end

  parser.on("-m MODE", "--mode=MODE", "read, write, read_write - defaults to read_write") do |m|
    case m
    when "read"
      mode = Mode::Read
    when "write"
      mode = Mode::Write
    when "read_write"
      mode = Mode::Read | Mode::Write
    else
      raise "invalid mode #{m.inspect}, must be one of read, write, read_write"
    end
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit 0
  end
end

metadata = {
  "wcp-webapp-user-preference" => %({
    "desktype": [],
    "level": "",
    "neighbourhood": [],
    "notifications": {
        "arrivals": {
            "email": true,
            "sms": true
        },
        "bookings": {
            "email": true,
            "sms": true
        }
    },
    "permissions": {
        "desks": "both",
        "lockers": "both",
        "rooms": "both"
    },
    "time": "All day"
}),
  "wcp-user-location-status" => %({
    "modified_at": "1655132432",
    "source": "WcpUserLocationAutoUpdate - reset",
    "status": "%status%"
}),
  "wcp-webapp-user-details" => %({
    "department": "",
    "designation": "Software Engineer (Verint)",
    "mobile": "",
    "modified_at": "1655467659",
    "neighbourhood": "55680",
    "office_address": "Heritage Lanes, Level 03 80 Ann Street",
    "source": "WcpUserSyncAADGroup",
    "team": "",
    "work_phone": ""
}),
  "wcp-webapp-user-status" => %({
    "status": "%status%"
}),
}

users = PlaceOS::Client.new(
  place_domain,
  host_header: place_domain,
  insecure: true,
  x_api_key: api_key
).users.search(limit: 10_000)

finished = Channel(Nil).new(2)

running = true
Signal::INT.trap do |signal|
  running = false
  puts "> shutdown requested"
  signal.ignore
end

if mode.read?
  readers = Channel(Nil).new(load)

  finished.send nil
  spawn do
    loop do
      readers.send nil
      break unless running

      # perform a read operation
      spawn do
        begin
          client = PlaceOS::Client.new(
            place_domain,
            host_header: place_domain,
            insecure: true,
            x_api_key: api_key
          )
          # hit auth
          client.authority.fetch

          # hit metadata
          user = users.sample
          metadata_name = metadata.keys.sample
          client.metadata.fetch(user.id, metadata_name)
        rescue error
          puts "write error: #{error.message}"
        ensure
          readers.receive
        end
      end
      Fiber.yield
    end
    puts "-- reads stopped"
    finished.receive
  end
end

if mode.write?
  writers = Channel(Nil).new(load)
  status = {"Available", "Unavailable"}

  finished.send nil
  spawn do
    loop do
      writers.send nil
      break unless running

      # perform a write operation
      spawn do
        begin
          user = users.sample
          metadata_name, metadata_value = metadata.sample
          metadata_value = metadata_value.gsub("%status%", status.sample)
          PlaceOS::Client.new(
            place_domain,
            host_header: place_domain,
            insecure: true,
            x_api_key: api_key
          ).metadata.update(user.id, metadata_name, JSON.parse(metadata_value), "")
        rescue error
          puts "write error: #{error.message}"
        ensure
          writers.receive
        end
      end
      Fiber.yield
    end
    puts "-- writes stopped"
    finished.receive
  end
end

# wait until both readers and writers are finished
finished.send nil
finished.send nil

puts "\n> exited normally"

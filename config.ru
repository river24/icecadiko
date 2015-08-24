# coding: utf-8
require 'uri'
require 'logger'
require 'net/http'
require 'sinatra'
require 'sinatra/streaming'

# icecast2 uri
icecast2_uri = URI.parse("http://#{ENV['ICECAST2_ADDR']}:#{ENV['ICECAST2_PORT']}#{ENV['ICECAST2_PATH']}")

# radiko command
radiko_script=::File.dirname(__FILE__) + "/scripts/radiko.bash"
stop_command="#{radiko_script} stop > /dev/null 2>&1 &"

# logger
AppLogger = ::Logger.new(::File.dirname(__FILE__) + "/log/app.log")
AppLogger.level = 0

rack_logger = ::Logger.new(::File.dirname(__FILE__) + "/log/rack.log")
rack_logger.instance_eval do
  alias :write :'<<'
end
use Rack::CommonLogger, rack_logger

# helper for logger
helpers do
  def logger
    if defined?(AppLogger)
      AppLogger
    else
      env['rack.logger']
    end
  end
end

get "/:station" do
  target_station = params[:station].to_s

  path = icecast2_uri.path.dup
  path << "?" << icecast2_uri.query if icecast2_uri.query
  request_headers = request.env.select { |k, v| k.start_with?('HTTP_') }

  system(stop_command)
  logger.info("Stop to play")

  count = 0
  while count < 10
    server = nil
    server = Net::BufferedIO.new(TCPSocket.new(icecast2_uri.host, icecast2_uri.port))

    server.writeline "GET #{path} HTTP/1.0"
    server.writeline ""

    proxy_response = Net::HTTPResponse.read_new(server)
    server.close
    if proxy_response.code.to_i == 404
      break
    end

    sleep 1
    count = count + 1
  end

  play_command="#{radiko_script} play #{target_station} > /dev/null 2>&1 &"
  system(play_command)
  logger.info("Start to play #{target_station}")

  on_air_flag = false

  count = 0
  while count < 20
    server = nil
    server = Net::BufferedIO.new(TCPSocket.new(icecast2_uri.host, icecast2_uri.port))

    server.writeline "GET #{path} HTTP/1.0"
    server.writeline ""

    proxy_response = Net::HTTPResponse.read_new(server)
    server.close
    if proxy_response.code.to_i == 200
      on_air_flag = true
      break
    end

    sleep 1
    count = count + 1
  end

  if on_air_flag
    server = nil
    server = Net::BufferedIO.new(TCPSocket.new(icecast2_uri.host, icecast2_uri.port))

    server.writeline "GET #{path} HTTP/1.0"
    request_headers.each do |k, v|
      server.writeline "#{k}: #{v}"
    end
    server.writeline ""

    proxy_response = Net::HTTPResponse.read_new(server)
    response.status = proxy_response.code.to_i
    proxy_response.each do |k, v|
      headers[k] = v
    end

    stream do |out|
      while true  do
        begin
          block=''
          server.read(4096, block)
        rescue EOFError => e
          break
        ensure
          if out.closed?
            server.close
            system(stop_command)
            logger.info("Stop to play")
            break
          else
            out << block unless out.closed?
          end
          if block=='' then
            break
          end
        end
      end
    end
  else
    response.status = 404
  end
end

after do
  cache_control :no_cache
end

run Sinatra::Application


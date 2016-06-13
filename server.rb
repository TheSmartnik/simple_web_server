require 'socket'
require 'uri'

server = TCPServer.new('localhost', '2193')

WEB_ROOT = './public'
HOME_PATH = File.join(WEB_ROOT, 'index.html')
CONTENT_TYPE_MAPPING = {
  html: 'text/html',
  txt: 'text/plain',
  png: 'image/png',
  jpg: 'image/jpeg'
}

DEFAULT_CONTENT_TYPE = 'application/octet-stream'

def content_type(path)
  ext = File.extname(path).split('.').last.to_sym
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

def requested_file(request_line)
  request_uri = request_line.split[1]
  path = URI.unescape URI(request_uri).path

  return HOME_PATH if path == '/'

  clean = []
  path.split('/').each do |part|
    next if part.empty? || part == '.'
    part == '..' ? clean.pop : clean << part
  end

  File.join(WEB_ROOT, *clean)
end

while true
  socket = server.accept
  request_line = socket.gets

  puts request_line

  path = requested_file(request_line)

  file = File.open(path) if File.exist?(path) && !File.directory?(path)
  if file.nil?
    response = "File not found\n"
    status = '404 Not Found'
    content_type = 'text/plain'
  else
    response = file.read
    puts response
    status = '200 OK'
    content_type = content_type(file)
  end

  socket.print "HTTP/1.1 #{status}\r\n" \
               "Content-Type: #{content_type}\r\n" \
               "Content-Length: #{response.size}\r\n" \
               "Connection: close\r\n"
  socket.print "\r\n"
  socket.print response
  socket.close
end

# CallMeLater

Rack middleware for asynchronous http request response cycle.

The idea is to create a worker, send the worker identifier to the client
and later resume it with arguments received via http request.

Worker are implemented using fibers and run inside an event-loop in
a separate thread so they can be created and resumed in a multithreaded
webserver.


## Usage

```ruby
require 'call_me_later'
require 'rack'
require 'thin'

class App
  def initialize
    @reply_service = CallMeLater::Hub.instance
  end


  def call(env)
    reply_id = @reply_service.wait do |response|
      #
      # Work with the response later on.
      #
      puts "Processing reply #{response}."
    end

    [
      '200',
      { 'Content-Type' => 'text/plain' },
      [reply_id.to_s] # The worker id as part of the response
    ]
  end
end



app = Rack::Builder.new do |builder|
  builder.use CallMeLater::Middleware
  builder.run App.new
end


Rack::Handler::Thin.run(app) do |server|
  server.threaded = true # Multithreaded webserver works
end
```

The response of `curl http://localhost:8080` will be the id of the
response and the parameters of `curl
http://localhost:8080/reply_service?id=<response_id>` will be forwarded
to the block and the computation will restarted.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/klotz-dabril/call_me_later.

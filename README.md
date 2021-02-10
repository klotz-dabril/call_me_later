# CallMeLater

Rack middleware for asynchronous http request response cycle.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'call_me_later'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install call_me_later

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
      [reply_id.to_s]
    ]
  end
end



app = Rack::Builder.new do |builder|
  builder.use CallMeLater::Middleware
  builder.run App.new
end


Rack::Handler::Thin.run(app)
```

The response of `curl http://localhost:8080` will be the id of the
response and the parameters of `curl
http://localhost:8080/reply_service?id=<response_id>` will be forwarded
to the block and the computation will restarted.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/klotz-dabril/call_me_later.

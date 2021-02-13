# frozen_string_literal: true

require 'spec_helper'

class BeyondCallMeLaterError < StandardError
end

RSpec.describe CallMeLater::Middleware do
  DEFAULT_ENDPOINT = '/reply_service'
  CUSTOM_ENDPOINT  = '/custom_endpoint'
  OTHER_ENDPOINT   = '/something_far_away'

  let(:app) { ->(env) { raise BeyondCallMeLaterError.new 'Go back home.' } }

  let(:default_middleware) { CallMeLater::Middleware.new(app) }
  let(:default_env)        { Rack::MockRequest.env_for(DEFAULT_ENDPOINT, method: :get) }

  let(:custom_middleware) { CallMeLater::Middleware.new(app, endpoint: CUSTOM_ENDPOINT) }
  let(:custom_env)        { Rack::MockRequest.env_for(CUSTOM_ENDPOINT, method: :get) }

  let(:other_endpoint_env) { Rack::MockRequest.env_for(OTHER_ENDPOINT, method: :get) }


  it 'forwards requests to the rest of the stack' do
    expect { default_middleware.call(other_endpoint_env) }.to raise_error(BeyondCallMeLaterError)
  end


  it "intializes with the default endpoint" do
    expect(default_middleware.endpoint).to be == DEFAULT_ENDPOINT
  end


  it "initializes with custom endpoint" do
    expect(custom_middleware.endpoint).to be == CUSTOM_ENDPOINT
  end


  it "it accepts requests" do
    expect { default_middleware.call default_env }.to_not raise_error
  end


  it "it accepts requests for custom_endpoints" do
    expect { custom_middleware.call custom_env  }.to_not raise_error
  end


  it "it ignores requests for DEFAULT_endpoint when CUSTOM_endpoint is set" do
    expect { custom_middleware.call default_env }.to raise_error(BeyondCallMeLaterError)
  end


  it "resumes a worker" do
    hub = CallMeLater::Hub.instance
    worker_probe = Queue.new
    worker_id    = hub.wait { |_| worker_probe.push(:resumed) }

    env = Rack::MockRequest.env_for(DEFAULT_ENDPOINT + "?id=#{worker_id}")
    default_middleware.call(env)

    expect(worker_probe.pop).to be == :resumed
  end


  it "forwards request parameters to worker on resume" do
    hub = CallMeLater::Hub.instance
    worker_probe = Queue.new
    worker_id    = hub.wait { |params| worker_probe.push(params) }

    env = Rack::MockRequest.env_for(DEFAULT_ENDPOINT + "?id=#{worker_id}&var=VAR")
    default_middleware.call(env)

    expect(worker_probe.pop['var']).to be == 'VAR'
  end


  it "request fails with 404 when worker does not exist" do
    hub = CallMeLater::Hub.instance
    worker_probe = Queue.new
    worker_id    = hub.wait { |_| worker_probe.push(:resumed) }

    env = Rack::MockRequest.env_for(DEFAULT_ENDPOINT + "?id=wrong_worker_id")
    response = default_middleware.call(env)

    expect(response[0]).to  be == '404'
    expect(response[2]).to  be == ['not_found']
    expect(worker_probe).to be_empty
  end
end

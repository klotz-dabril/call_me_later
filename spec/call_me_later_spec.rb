# frozen_string_literal: true

require 'spec_helper'


RSpec.describe CallMeLater do
  # let(:env) { Rack::MockRequest.env_for        }
  # let(:app) { ->(env) { [200, {}, "success"] } }
  # let(:hub) { CallMeLater::Hub.instance        }


  # subject { CallMeLater::Middleware.new(app) }


  it "has a version number" do
    expect(CallMeLater::VERSION).not_to be nil
  end

  # it "does something useful" do
    # add_call = Rack::MockRequest.env_for ''
    # binding.pry

    # expect(false).to eq(true)
  # end
end

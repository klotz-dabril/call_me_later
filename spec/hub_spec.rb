# frozen_string_literal: true

require 'spec_helper'


RSpec.describe CallMeLater::Hub do
  subject { CallMeLater::Hub.instance }


  it "is a singleton" do
    hub_1 = CallMeLater::Hub.instance
    hub_2 = CallMeLater::Hub.instance

    expect(hub_1).to equal(hub_2)
  end


  it "adds and retrieves a worker" do
    worker_probe = Queue.new

    worker_id = subject.wait do |response|
      worker_probe.push response
    end

    worker_response = subject.resume worker_id, :success

    expect(worker_response[:success]).to be true
    expect(worker_response[:status]).to  be :ok

    expect(worker_probe.pop).to be :success
  end


  it "fails whith ':not_found' when resuming a non existing worker" do
    worker_probe = Queue.new

    worker_id = subject.wait do |response|
      worker_probe.push response
    end

    worker_response = subject.resume 'wrong_worker_id', :success

    expect(worker_response[:success]).to be_falsy
    expect(worker_response[:status]).to  be :not_found

    expect(worker_probe).to be_empty
  end


  it 'forgets worker after resume' do
    worker_id = subject.wait do |response|
      # doing my thing...
    end

    _               = subject.resume worker_id # first resume
    worker_response = subject.resume worker_id # second resume

    expect(worker_response[:status]).to  be :not_found
  end


  it 'works with different threads' do
    other_thread = Thread.new do
      subject.wait do |response|
        # working...
      end
    end

    worker_response = subject.resume other_thread.value

    expect(worker_response[:status]).to  be :ok
  end


  # #
  # # TODO
  # # What should be expected when the worker goes boom??
  # #
  # # * decent log, minimun!
  # #
  # it "does stuff when worker explodes" do
    # worker_id = subject.wait do |response|
      # raise StandardError.new 'Worker is broken!'
    # end

    # worker_response = subject.resume worker_id, :success
  # end
end

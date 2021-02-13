# frozen_string_literal: true
#
#

require 'fiber'
require 'singleton'


module CallMeLater
  class Hub
    include Singleton


    def initialize
      @mutex   = Mutex.new
      @queue   = Queue.new
      @workers = {}

      run_forest_run!
    end


    def wait(&block)
      # TODO
      # Check if a different ConditionVariable is really needed.
      condition_variable = ConditionVariable.new

      id = rand(10000).to_s.to_sym # TODO get a better id system!!!!!!!!

      @queue.push what:     :new,
                  who:      id,
                  job:      block,
                  resource: condition_variable

      # Only proceed after fiber is created and waiting. Otherwise if
      # the event loop is too busy, the response may come before the
      # workder is all set and confy.
      @mutex.synchronize { condition_variable.wait(@mutex) }

      id
    end


    def resume(id, response=nil)
      worker = @workers.delete(id) # TODO Thread safe? Try to break it!!

      return {error: true, status: :not_found} unless worker

      @queue.push(
        what:     :resume,
        who:      id,
        response: response,
        worker:   worker
      )

      {success: true, status: :ok}
    end


    private
      def run_forest_run!
        Thread.new do
          loop do
            case @queue.pop
            in {what: :new, who:, job:, resource:}
              new_worker(who: who, job: job).resume
              resource.signal

            in {what: :resume, who:, response:, worker:}
              worker.resume(response)
            end
          end
        end
      end


      def new_worker(who:, job:)
        Fiber.new do
          @workers[who] = Fiber.current
          response = Fiber.yield
          job.call(response)
        end
      end
  end
end

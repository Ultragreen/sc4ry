# frozen_string_literal: true

# Sc4ry module
# @note namespace
module Sc4ry
  # class Facility to run and update values/status for a circuit Proc
  class RunController
    # return the execution time of the proc
    attr_reader :execution_time

    # constructor
    # @param [Hash] circuit the data of the circuit
    def initialize(circuit = {})
      @circuit = circuit
      @execution_time = 0
      @timeout = false
      @failure = false
      @overtime = false
    end

    # return if the Proc failed on a covered exception by this circuit
    # @return [Boolean]
    def failed?
      @failure
    end

    # return if the Proc overtime the specified time of the circuit
    # @return [Boolean]
    def overtimed?
      @overtime
    end

    # return if the Proc timeout the timeout defined value of the circuit, if timeout is active
    # @return [Boolean]
    def timeout?
      @timeout
    end

    # run and update values for the bloc given by keyword
    # @param [Proc] block a block to run and calculate
    # @return [Hash] a result Hash
    def run(block:)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        if @circuit[:timeout] == true
          Timeout.timeout(@circuit[:timeout_value]) do
            block.call
          end
          @timeout = false
        else
          block.call
        end
      rescue StandardError => e
        @last_exception = e.class.to_s
        if e.instance_of?(Timeout::Error)
          @timeout = true
        elsif @circuit[:exceptions].include? e.class
          @failure = true
        elsif @circuit[:forward_unknown_exceptions]
          raise e.class, "Sc4ry forward: #{e.message}"
        else
          Sc4ry::Helpers.log level: :debug, message: "skipped : #{@last_exception}"

        end
      end
      @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @execution_time = @end_time - start_time
      @overtime = @execution_time > @circuit[:max_time]
      { failure: @failure, overtime: @overtime, timeout: @timeout, execution_time: @execution_time,
        end_time: @end_time, last_exception: @last_exception }
    end
  end
end

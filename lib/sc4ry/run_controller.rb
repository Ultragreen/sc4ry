
module Sc4ry
  class RunController

    attr_reader :execution_time

    def initialize(circuit = {})
      @circuit = circuit
      @execution_time = 0
      @timeout = false
      @failure = false
      @overtime = false
    end

    def failed?
      return @failure
    end 
    
    def overtimed? 
      return @overtime
    end

    def timeout? 
      return @timeout
    end

    
    def run(options = {})
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin 
        if @circuit[:timeout] == true
          Timeout::timeout(@circuit[:timeout_value]) do 
            options[:block].call
          end
          @timeout = false
        else
          options[:block].call
        end
      rescue Exception => e
        @last_exception = e.class.to_s
        if e.class  == Timeout::Error then 
          @timeout = true
        elsif @circuit[:exceptions].include? e.class
          @failure = true
        else  
          if @circuit[:forward_unknown_exceptions] then

            raise e.class, "Sc4ry forward: #{e.message}" 
          else
            Sc4ry::Helpers.log level: :debug, message: "skipped : #{@last_exception}"
          end
          
        end 
      end
      @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @execution_time = @end_time - start_time
      @overtime = @execution_time > @circuit[:max_time] 
      return {failure: @failure, overtime: @overtime, timeout: @timeout, execution_time: @execution_time, end_time: @end_time, last_exception: @last_exception}

    end



  end
end
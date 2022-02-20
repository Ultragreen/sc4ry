#require "sc4ry/version"

require 'rest-client'



require 'logger' 
require 'timeout'
require 'forwardable'
require 'singleton'





module Sc4ry


 



   

  module Backends



    class Memory
      def initialize(config=nil?)
        @data = Hash::new
      end

      def list
        return @data.keys
      end

      def get(options)
        return @data[options[:key]]
      end

      def put(options)
        @data[options[:key]] = options[:value]
      end 

      def del(options)
        @data.delete options[:key]
      end 

      def flush
        @data.clear
      end

      def exist?(options)
        return @data.include? options[:key]
      end



    end

    # Redis backend definition
    class Redis

      # Constructor
      # @param [Hash] config Config map 
      # @return [Sc4ry::Backends::Redis] a Redis backend
      def initialize(config)
        @auth = config.slice(:auth)[:auth]
        @config = config.slice(:host, :port, :db)
        @be = ::Redis.new @config
        @be.auth(@auth) if @auth
      end

      # return the list of find records in backend for a specific pattern
      # @return [Array] list of record (for all hostname if hostname is specified)
      def list
         return @store.keys('*')
      end


      # return value of queried record
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [String] content value of record
      def get(options)
        return @store.get(options[:key])
      end

      # defined and store value for specified key
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @option options [Symbol] :value the content value of the record
      # @return [String] content value of record
      def put(options)
        @store.set options[:key], options[:value]
      end

      # delete a specific record
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [Boolean] status of the operation
      def del(options)
        @store.del options[:key]
      end

      # flush all records in backend
      def flush
        @store.flushdb
      end

      # verifiy a specific record existance
      # @param [Hash] options
      # @option options [Symbol] :key the name of the record
      # @return [Boolean] presence of the record
      def exist?(options)
        return ( not @store.get(options[:key]).nil?)
      end
    

    end

  end


  class Store

    @@current = :memory

    extend Forwardable
    include Singleton

    @@backends = {:memory => {:class => Sc4ry::Backends::Memory},
                  :redis  => {:class => Sc4ry::Backends::Redis, :config => {:host => 'localhost', :port => 6379, :db => 10 }}}

    attr_reader :be
    def_delegators :@be, :put, :get, :flush, :exist?, :del, :list

    def initialize
      change_backend name: @@current 
    end 

    def current
      return @@current
    end

    def change_backend(options)
      @@current = options[:name]
      @be = @@backends[@@current][:class]::new 
    end

    def register_backend(options)
      raise ":name is mandatory" unless options[:name]
      raise ":definition is mandatory" unless options[:definition]
      @@backends[options[:name]] = options[:definition]
    end

    def config_backend(options)
      raise ":name is mandatory" unless options[:name]
      raise ":config is mandatory" unless options[:config]
      @@backends[options[:name]][:config] = options[:config]
    end


  end





  module Notifiers
    
  end



  class Logger

    @@loggers = {:stdout => ::Logger.new(STDOUT)}
    @@current = :stdout

    def Logger.list_avaible
      return @@loggers
    end

    def Logger.current
      return @@current
    end

    def Logger.get
      return @@loggers[@@current]
    end

    def Logger.current=(sym)
       raise "Logger not define : #{sim}" unless @@loggers.keys.include? sim
      @@default = sym
    end

    def Logger.register(options = {})
      @@loggers[options[:name]] = options[:instance] 
    end

  end

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
        @last_exception = e.class
        if e.class  == Timeout::Error then 
          @timeout = true
        elsif @circuit[:exceptions].include? e.class
          @failure = true
        else  
          Sc4ry::Loggers.warning "skipped : #{@last_exception}"
        end 
      end
      @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @execution_time = @end_time - start_time
      @overtime = @execution_time > @circuit[:max_time] 
      return {failure: @failure, overtime: @overtime, timeout: @timeout, execution_time: @execution_time, end_time: @end_time, last_exception: @last_exception}

    end

    private
    def run!(options = {})
      block  = 
      
   
        block.call
      
    end

  end

  class Circuits

      @@circuits_store = Sc4ry::Store.instance 

      @@config = { :max_failure_count => 5,
                   :timeout_value => 20,
                   :timeout => false,
                   :max_timeout_count => 5,
                   :max_time => 10,
                   :max_overtime_count => 3,
                   :check_delay => 30,
                   :exceptions => [StandardError, RuntimeError]
                   }

      def Circuits.default_config
        return @@config
      end

      def Circuits.register(options = {})
        raise ":circuit is mandatory" unless options[:circuit]
        name = options[:circuit]
        override = (options[:config].class == Hash)? options[:config] : {}
        config = @@config.merge override
        @@circuits_store.put key: name, value: config 
      end

      def Circuits.list
        return @@circuits_store.list
      end


      def Circuits.get(options)
        @@circuits_store.get key: options[:circuit]
      end

      def Circuits.run(options = {}, &block)
        circuits_list = Circuits.list
        raise "No circuit block given" unless block_given?
        raise "No circuits defined" if circuits_list.empty? 
        circuit_name = (options[:circuit])? options[:circuit] : circuits_list.first
        raise "Circuit #{circuit_name} not found" unless circuits_list.include? circuit_name
        circuit = Circuits.get circuit: circuit_name
        skip = false
        if circuit.include? :status then
          if circuit[:status][:general] == :open then 
            @now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            skip = true if ((@now - circuit[:values].last[:end_time]) <  circuit[:check_delay])
          end
        end
        unless skip 
          controller = Sc4ry::RunController.new(circuit)
          Circuits.control circuit: circuit_name, values: controller.run(block: block)
        end
        Circuits.log_iteration circuit: circuit_name
      end

      private

      def Circuits.log_iteration(options={})
        data = @@circuits_store.get key: options[:circuit]
        Sc4ry::Logger.get.info "Sc4ry : Circuit #{options[:circuit]} : status #{data[:status]}"
      end

      def Circuits.control(options={})
        data = @@circuits_store.get key: options[:circuit]
        data[:status] = {:general => :closed, :failure_count => 0, :overtime_count => 0, :timeout_count => 0} unless data.include? :status
        data[:values] = Array::new unless data.include? :values
        level = [data[:max_failure_count].to_i, data[:max_timeout_count].to_i, data[:max_overtime_count].to_i].max
        data[:values].shift if data[:values].size > level
        data[:values].push options[:values]
        worst_status = []
        ['failure','overtime','timeout'].each do |control|
          if options[:values][control.to_sym] == true then
            data[:status]["#{control}_count".to_sym] += 1
          else
            data[:status]["#{control}_count".to_sym] = 0
          end
      
          case data[:status]["#{control}_count".to_sym]
          when 0
            worst_status.push :closed
          when 1..data["max_#{control}_count".to_sym]
            worst_status.push :half_open
          else
            worst_status.push :open
          end
        end
        [:closed,:half_open,:open].each do |status|
          data[:status][:general] = status if worst_status.include? status
        end          
        @@circuits_store.put key: options[:circuit], value: data
      end


  end

end




Sc4ry::Circuits.register({:circuit =>:test, :config => {:exceptions => [Errno::ECONNREFUSED], :timeout =>  true, :timeout_value => 3, :check_delay => 5 }})


# pp Sc4ry::Circuits.list
# pp Sc4ry::Circuits.get circuit: :test


100.times do
  sleep 1
  Sc4ry::Circuits.run circuit: :test do 
   puts RestClient.get('http://localhost:9292/test2/data')
  end
end




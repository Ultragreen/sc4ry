module Sc4ry
    module Backends
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
end  
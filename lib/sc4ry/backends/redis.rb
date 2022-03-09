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
           return @be.keys('*').map(&:to_sym)
        end
  
  
        # return value of queried record
        # @param [Hash] params
        # @option params [Symbol] :key the name of the record
        # @return [String] content value of record
        def get(key:)
          return YAML.load(@be.get(key))
        end
  
        # defined and store value for specified key
        # @param [Hash] params
        # @option params [Symbol] :key the name of the record
        # @option params [Symbol] :value the content value of the record
        # @return [String] content value of record
        def put(key: ,value:)
          @be.set key, value.to_yaml
        end
  
        # delete a specific record
        # @param [Hash] params
        # @option params [Symbol] :key the name of the record
        # @return [Boolean] status of the operation
        def del(key: )
          @be.del key
        end
  
        # flush all records in backend
        def flush
          @be.flushdb
        end
  
        # verifiy a specific record existance
        # @param [Hash] params
        # @option params [Symbol] :key the name of the record
        # @return [Boolean] presence of the record
        def exist?(key: )
          return ( not @be.get(key).nil?)
        end
      
  
      end
  
    end
end  
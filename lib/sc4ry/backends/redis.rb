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
        @be.keys('*').map(&:to_sym)
      end

      # return value of queried record
      # @param key [Symbol] the name of the record
      # @return [String] content value of record
      def get(key:)
        res = YAML.load(@be.get(key))
        res[:exceptions].map! { |item| item = Object.const_get(item) if item.instance_of?(String) }
        res
      end

      # defined and store value for specified key
      # @param key [Symbol] :key the name of the record
      # @param value [Symbol] :value the content value of the record
      # @return [String] content value of record
      def put(key:, value:)
        data = value.dup
        data[:exceptions].map! { |item| item = item.name.to_s if item.instance_of?(Class) }
        @be.set key, data.to_yaml
      end

      # delete a specific record
      # @param key [Symbol] the name of the record
      # @return [Boolean] status of the operation
      def del(key:)
        @be.del key
      end

      # flush all records in backend
      # @return [Boolean] status of the operation
      def flush
        @be.flushdb
      end

      # verifiy a specific record existence
      # @param key [Symbol] the name of the record
      # @return [Boolean] presence of the record
      def exist?(key:)
        !@be.get(key).nil?
      end
    end
  end
end

module Sc4ry
  module Backends

    class Memory
              
        # Constructor
        # @param [Hash] config Config map 
        # @return [Sc4ry::Backends::Memory] a in Memory backend
      def initialize(config=nil?)
        @data = Hash::new
      end

      # return the list of find records in backend for a specific pattern
      # @return [Array] list of record (for all hostname if hostname is specified)
      def list
        return @data.keys
      end

      # return value of queried record
      # @param key [Symbol] the name of the record
      # @return [String] content value of record
      def get(key: )
        return @data[key]
      end

      # defined and store value for specified key
      # @param key [Symbol] :key the name of the record
      # @param value [Symbol] :value the content value of the record
      # @return [String] content value of record
      def put(key:, value: )
        @data[key] = value
      end 

      # delete a specific record
      # @param params [Symbol] the name of the record
       # @return [Boolean] status of the operation
      def del(key: )
        @data.delete key
      end 

      # flush all records in backend
      # @return [Boolean] status of the operation
      def flush
        @data.clear
      end

      # verifiy a specific record existence
      # @param key [Symbol] the name of the record
      # @return [Boolean] presence of the record
      def exist?(key: )
        return @data.include? key
      end

    end
  end
end
module Sc4ry
  module Backends

    class Memory
      def initialize(config=nil?)
        @data = Hash::new
      end

      def list
        return @data.keys
      end

      def get(key: )
        return @data[key]
      end

      def put(key:, value: )
        @data[key] = value
      end 

      def del(key: )
        @data.delete key
      end 

      def flush
        @data.clear
      end

      def exist?(key: )
        return @data.include? key
      end

    end
  end
end
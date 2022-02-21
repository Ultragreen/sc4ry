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
  end
end
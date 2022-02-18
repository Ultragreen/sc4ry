#require "sc4ry/version"

require 'logger' 

module Sc4ry
  class Error < StandardError; end
  class Circuits

    def Circuits.run(options = {}, &block)
      p 'toto' if block_given?
      p block
      circuits = CircuitsMap.list
      p circuits 
      raise "No circuits defined" if circuits.empty?  
      circuit_name = (options[:circuit])? options[:circuit] : circuits.keys.first
      p circuit_name
      raise "Circuit #{circuit_name} not found" unless  circuits.include? circuit_name
      circuit = circuits[circuit_name] 
      p circuit 
      block.call 
    end

  end

  class CircuitsMap

      @@circuits = {}

      @@config = { :logger => Logger.new(STDOUT),
                   :max_failure_count => 5,
                   :max_timeout => 10,
                   :max_timeout_count => 3,
                   :check_delay => 30,
                   :exceptions => []}

      def CircuitsMap.default_config
        return @@config
      end

      def CircuitsMap.register(options = {})
        raise ":name is mandatory" unless options[:name]

        name = options[:name]
        override = (options[:config].class == Hash)? options[:config] : {}
        config = @@config.merge override
        @@circuits[name ] = config 
      end

      def CircuitsMap.list
        return @@circuits
      end

  end

end

include Sc4ry

Sc4ry::CircuitsMap.register name: :test

pp Sc4ry::CircuitsMap.default_config
pp Sc4ry::CircuitsMap.list

pp Sc4ry::Circuits.run do |titi|
  puts 'titi'
end
# Sc4ry module
# @note namespace
module Sc4ry
  # Sc4ry loggers Factory/provider
  # @note must be accessed by [Sc4ry::Circuits.loggers]
  class Loggers
    @@loggers = { stdout: ::Logger.new($stdout) }
    @@current = :stdout

    # give the list of available loggers (initially internal Sc4ry logger )
    # @return [Array] of [symbol] the list of defined loggers
    # @note default :stdout => ::Logger($stdout) from Ruby Stdlib
    # @example usage
    #    include Sc4ry
    #    Circuits.loggers.list_available.each {|logger| puts logger }
    def self.list_available
      @@loggers.keys
    end

    # return the current logger name (initially :stdtout )
    # @return [symbol] the name of the logger
    # @example usage
    #    include Sc4ry
    #    puts Circuits.loggers.current
    def self.current
      @@current
    end

    # return the current logger Object (initially internal Sc4ry Stdlib Logger on STDOUT )
    # @return [symbol] the name of the logger
    # @example usage
    #    include Sc4ry
    #    Circuits.loggers.get :stdout
    def self.get
      @@loggers[@@current]
    end

    # Set the current logger
    # @param [Symbol] sym the name of the logger
    # @return [symbol] the name of the logger updated
    # @example usage
    #    include Sc4ry
    #    Circuits.loggers.current = :newlogger
    def self.current=(sym)
      raise "Logger not define : #{sym}" unless @@loggers.keys.include? sym

      @@current = sym
      @@current
    end

    # register un new logger
    # @param [Symbol] name the name of the new logger
    # @param [Object] instance the new logger object
    # raise Sc4ry::Exceptions::Sc4ryGenericError if name is not a Symbol
    # @example usage
    #    include Sc4ry
    #    Circuits.loggers.register name: :newlogger, instance: Logger::new('/path/to/my.log')
    def self.register(name:, instance:)
      raise Sc4ry::Exceptions::Sc4ryGenericError, 'name: keyword must be a Symbol' unless name.instance_of?(Symbol)

      @@loggers[name] = instance
      name
    end
  end
end

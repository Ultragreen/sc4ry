
module Sc4ry
  class Logger
    
    @@loggers = {:stdout => ::Logger.new(STDOUT)}
    @@current = :stdout
    
    def Logger.list_available
      return @@loggers.keys
    end
    
    def Logger.current
      return @@current
    end
    
    def Logger.get
      return @@loggers[@@current]
    end
    
    def Logger.current=(sym)
      raise "Logger not define : #{sym}" unless @@loggers.keys.include? sym
      @@current = sym
      return @@current
    end
    
    def Logger.register(name: , instance: )
      raise Sc4ry::Exceptions::Sc4ryGenericError, "name: keyword must be a Symbol" unless name.class == Symbol
      @@loggers[name] = instance
      return name
    end
    
  end
end

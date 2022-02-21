
module Sc4ry
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
end

module Sc4ry
    module Exceptions
        class CircuitBreaked < StandardError
            def initialize(msg="Circuit just opened")
                super(msg)
              end
        
        end

        class Sc4ryGenericError < StandardError
            def initialize(msg="")
                super(msg)
              end
        
        end

        class Sc4ryBackendError < StandardError
            def initialize(msg)
                super(msg)
              end
        
        end

        class ConfigError < StandardError
            def initialize(msg)
                super(msg)
              end
        
        end

    end
end
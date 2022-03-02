module Sc4ry
    module Exceptions
        class CircuitBreaked < StandardError
            def initialize(msg="Circuit just opened")
                super(msg)
              end
        
        end

    end
end
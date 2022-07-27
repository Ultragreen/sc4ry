# Sc4ry module
# @note namespace
module Sc4ry
  # Sc4ry::Exceptions module
  # @note namespace
  module Exceptions
    # Exception use in {Sc4ry::Circuits} when running circuit {Sc4ry::Circuits::run}
    class CircuitBreaked < StandardError
      def initialize(msg = 'Circuit just opened')
        super(msg)
      end
    end

    # Generic Exception use in {Sc4ry::Circuits}
    class Sc4ryGenericError < StandardError
      def initialize(msg = '')
        super(msg)
      end
    end

    # Exception use in {Sc4ry::Store} or/and {Sc4ry::Backend} on data string issues
    class Sc4ryBackendError < StandardError
      def initialize(msg = '')
        super(msg)
      end
    end

    # Exception use in {Sc4ry::Notifiers} on notification issues
    class Sc4ryNotifierError < StandardError
      def initialize(msg = '')
        super(msg)
      end
    end

    # Exception use in {Sc4ry::Circuits} on config management issues
    class ConfigError < StandardError
      def initialize(msg = '')
        super(msg)
      end
    end
  end
end

# Sc4ry module
# @note namespace
module Sc4ry
  # Sc4ry::Store class
  # Store Class Provider/manager singleton Forwarder on {Sc4ry::Backends::Memory} or {Sc4ry::Backends::Redis}
  # @note must be accessed by {Sc4ry::Circuits.store}
  class Store
    @@current = :memory

    extend Forwardable
    include Singleton

    @@backends = { memory: { class: Sc4ry::Backends::Memory, config: {} },
                   redis: { class: Sc4ry::Backends::Redis, config: { host: 'localhost', port: 6379, db: 1 } } }

    # accessor on current backend (default :memory)
    attr_reader :be

    def_delegators :@be, :put, :get, :flush, :exist?, :del, :list

    # constructor pointing on :memory backend
    def initialize
      change_backend name: @@current
    end

    # return the current backend
    # @return [Object] in {Sc4ry::Backends::Memory} or {Sc4ry::Backends::Redis}
    # @example usage
    #    include Sc4ry
    #    puts Circuits.store.current
    def current
      @@current
    end

    # return  the config of a specific backend
    # @param [Symbol] backend the name the backend
    # @return [Hash] the config of the backend
    # @raise  Sc4ry::Exceptions::Sc4ryBackendError if backend is not found
    # @example usage
    #    include Sc4ry
    #    puts Circuits.store.get_config backend: :redis
    def get_config(backend:)
      raise Sc4ry::Exceptions::Sc4ryBackendError, "backend #{backend} not found" unless @@backends.include? backend

      @@backends[backend][:config]
    end

    # list backend available
    # @return [Array] of Symbol the list of backend name
    # @example usage
    #    include Sc4ry
    #    puts Circuits.store.list_backend
    def list_backend
      @@backends.keys
    end

    # change the current backend
    # @note if changing form :memory to :redis => all values and result are lost and circuits will be lost
    # @note if changing to :redis, get all the define circuits with values and status (ideal)
    # @note for distributed worker/instance/runner/services
    # @param [Symbol] name the name of the target backend
    # @return [Symbol] the name of the new current backend
    # @raise Sc4ry::Exceptions::Sc4ryBackendError if backend is not found
    def change_backend(name:)
      raise Sc4ry::Exceptions::Sc4ryBackendError, "backend #{name} not found" unless @@backends.include? name

      @@current =  name
      @be = @@backends[@@current][:class].new(@@backends[@@current][:config])
      name
    end

    # register a new backend
    # @param [Symbol] name the name of the backend
    # @param [Hash] config the config for this backend
    # @param [Class] backend_class the class name of the new backend
    # @raise Sc4ry::Exceptions::Sc4ryBackendError if backend already exist
    # @return [Symbol] the name of the backend
    def register_backend(name:, backend_class:, config: {})
      raise Sc4ry::Exceptions::Sc4ryBackendError, "backend #{name} already exist" if @@backends.include? name

      @@backends[name] = { config: config, class: backend_class }
      name
    end

    # delete the specified backend reference
    # @param [Symbol] name the name of the target backend
    # @raise Sc4ry::Exceptions::Sc4ryBackendError if backend is not found, or name == :memory or :redis
    # @return [Boolean]
    def delete_backend(name:)
      forbidden_mes = 'Delete forbidden for backend in [:redis,:memory]'
      notfound_mes = "backend #{name} not found"
      raise Sc4ry::Exceptions::Sc4ryBackendError, forbidden_mes if %i[memory redis].include? name
      raise Sc4ry::Exceptions::Sc4ryBackendError, notfound_mes  unless @@backends.include? name

      @@backends.delete(name)
    end

    # change the specified backend config
    # @param [Symbol] name the name of the target backend
    # @param [Hash] config the config of the specified backend
    # @raise Sc4ry::Exceptions::Sc4ryBackendError if backend is not found, or name == :memory
    def config_backend(name:, config:)
      raise Sc4ry::Exceptions::Sc4ryBackendError, "backend #{name} not found" unless @@backends.include? name
      raise Sc4ry::Exceptions::Sc4ryBackendError, 'backend :memory not need config' if name == :memory

      @@backends[name][:config] = config
    end
  end
end

module Sc4ry
  class Store

    @@current = :memory

    extend Forwardable
    include Singleton

    @@backends = {:memory => {:class => Sc4ry::Backends::Memory, config: {}},
                  :redis  => {:class => Sc4ry::Backends::Redis, :config => {:host => 'localhost', :port => 6379, :db => 10 }}}

    attr_reader :be
    def_delegators :@be, :put, :get, :flush, :exist?, :del, :list

    def initialize
      change_backend name: @@current 
    end 

    def current
      return @@current
    end

    def display_config(backend: )
      raise Sc4ry::Exceptions::Sc4ryBackendError, "backend #{backend} not found" unless @@backends.include? backend
      return @@backends[backend][:config]
    end

    def list_backend
      return @@backends.keys
    end

    def change_backend(name: )
      raise Sc4ry::Exceptions::Sc4ryBackendError, "backend #{name} not found" unless @@backends.include? name
      @@current =  name
      @be = @@backends[@@current][:class]::new(@@backends[@@current][:config])
      return name
    end

    def register_backend(name:, config: {}, backend_class:)
      @@backends[name] = {config: config, class: backend_class}
    end
 
    def config_backend(name:, config:)
      @@backends[name][:config] = config
    end


  end
end
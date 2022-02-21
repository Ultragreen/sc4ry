module Sc4ry
  class Store

    @@current = :memory

    extend Forwardable
    include Singleton

    @@backends = {:memory => {:class => Sc4ry::Backends::Memory},
                  :redis  => {:class => Sc4ry::Backends::Redis, :config => {:host => 'localhost', :port => 6379, :db => 10 }}}

    attr_reader :be
    def_delegators :@be, :put, :get, :flush, :exist?, :del, :list

    def initialize
      change_backend name: @@current 
    end 

    def current
      return @@current
    end

    def change_backend(options)
      @@current = options[:name]
      @be = @@backends[@@current][:class]::new(@@backends[@@current][:config])
    end

    def register_backend(options)
      raise ":name is mandatory" unless options[:name]
      raise ":definition is mandatory" unless options[:definition]
      @@backends[options[:name]] = options[:definition]
    end

    def config_backend(options)
      raise ":name is mandatory" unless options[:name]
      raise ":config is mandatory" unless options[:config]
      @@backends[options[:name]][:config] = options[:config]
    end


  end
end
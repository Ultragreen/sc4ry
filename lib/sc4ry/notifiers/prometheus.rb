module Sc4ry
  module Notifiers

  
    class Prometheus

      @@registry = ::Prometheus::Client::Registry::new
      @@metric_circuit_state = ::Prometheus::Client::Gauge.new(:cuircuit_state, docstring: 'Sc4ry metric : state of a circuit', labels: [:circuit])

      @@registry.register(@@metric_circuit_state)

    

      # send metrics to Prometheus PushGateway
      # @return [Bool]
      def Prometheus.notify(options = {})
        @config = Sc4ry::Notifiers.get({name: :prometheus})[:config]
        status = options[:config][:status][:general]
        circuit = options[:circuit]
        status_map = {:open => 0, :half_open => 1, :closed => 2}
        if Sc4ry::Helpers::verify_service url: @config[:url] then
          
          @@metric_circuit_state.set(status_map[status], labels: {circuit: circuit.to_s })
          Sc4ry::Helpers.log level: :debug, message: "Prometheus Notifier : notifying for circuit #{circuit.to_s}, state : #{status.to_s}."

          return ::Prometheus::Client::Push.new(job: "Sc4ry", instance: Socket.gethostname, gateway: @config[:url]).add(@@registry)
        else
          Sc4ry::Helpers.log level: :warn, message: "Prometheus Notifier : can't notify Push Gateway not reachable."
        end
      end
    end

    @@notifiers_list = {:prometheus => {:class => Sc4ry::Notifiers::Prometheus, :config => {:url => 'http://localhost:9091'}}}

    def Notifiers.list
      return @@notifiers_list.keys
    end

    def Notifiers.get(options ={})
      return @@notifiers_list[options[:name]]
    end

    def Notifiers.register(options)
      raise ":name is mandatory" unless options[:name]
      raise ":definition is mandatory" unless options[:definition]
      @@notifiers_list[options[:name]] = options[:definition]
    end

    def Notifiers.config(options)
      raise ":name is mandatory" unless options[:name]
      raise ":config is mandatory" unless options[:config]
      @@notifiers_list[options[:name]][:config] = options[:config]
    end

    

  end

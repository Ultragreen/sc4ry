# frozen_string_literal: true

# Sc4ry module
# @note namespace
module Sc4ry
  # Sc4ry::Notifiers module
  # @note namespace
  module Notifiers
    # Prometheus notifier class
    class Prometheus
      @@registry = ::Prometheus::Client::Registry.new
      @@metric_circuit_state = ::Prometheus::Client::Gauge.new(:cuircuit_state,
                                                               docstring: 'Sc4ry metric : state of a circuit',
                                                               labels: [:circuit])

      @@registry.register(@@metric_circuit_state)

      # send metrics to Prometheus PushGateway
      # @return [Bool]
      def self.notify(options = {})
        @config = Sc4ry::Notifiers.get(name: :prometheus)[:config]
        status = options[:config][:status][:general]
        circuit = options[:circuit]
        status_map = { open: 0, half_open: 1, closed: 2 }
        if Sc4ry::Helpers.verify_service url: @config[:url]

          @@metric_circuit_state.set(status_map[status], labels: { circuit: circuit.to_s })
          Sc4ry::Helpers.log level: :debug,
                             message: "Prometheus Notifier : notifying for circuit #{circuit}, state : #{status}."

          ::Prometheus::Client::Push.new(job: 'Sc4ry', instance: Socket.gethostname,
                                         gateway: @config[:url]).add(@@registry)
        else
          Sc4ry::Helpers.log level: :warn, message: "Prometheus Notifier : can't notify Push Gateway not reachable."
        end
      end
    end
  end
end

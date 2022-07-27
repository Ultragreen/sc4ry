# frozen_string_literal: true

# Sc4ry module
# @note namespace
module Sc4ry
  # Sc4ry::Helpers module
  # @note namespace
  module Helpers
    # class method (module) to help logging messages
    # @param [Symbol] target a specific logger, restored old after
    # @param [Symbol] level (default :info) a logging level (see Logger Stdlib)
    # @param [String] message your message
    # @return [Boolean]
    def self.log(message:, target: nil, level: :info)
      save = Sc4ry::Loggers.current
      Sc4ry::Loggers.current = target if target
      Sc4ry::Loggers.get.send level, "Sc4ry : #{message}"
      Sc4ry::Loggers.current = save
      true
    end

    # TCP/IP service checker
    # @return [Bool] status
    # @param [Hash] options
    # @option options [String] :host hostname
    # @option options [String] :port TCP port
    # @option options [String] :url full URL, priority on :host and :port
    def self.verify_service(options = {})
      if options[:url]
        uri = URI.parse(options[:url])
        host = uri.host
        port = uri.port
      else
        host = options[:host]
        port = options[:port]
      end
      Timeout.timeout(1) do
        s = TCPSocket.new(host, port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    rescue Timeout::Error
      false
    end

    # class method (module) to help send notifiesby Sc4ry::Notifiers
    # @param [Hash] options a Notifying structure
    # @return [Boolean]
    def self.notify(options = {})
      Sc4ry::Notifiers.list.each do |record|
        notifier = Sc4ry::Notifiers.get name: record
        notifier[:class].notify(options) if options[:config][:notifiers].include? record
      end
    end
  end
end

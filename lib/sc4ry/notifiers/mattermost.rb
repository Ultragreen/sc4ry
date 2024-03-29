# frozen_string_literal: true

# Sc4ry module
# @note namespace
module Sc4ry
  # Sc4ry::Notifiers module
  # @note namespace
  module Notifiers
    # Mattermost Notifier class
    class Mattermost
      # send metrics to Prometheus PushGateway
      # @return [Bool]
      def self.notify(options = {})
        config = Sc4ry::Notifiers.get(name: :mattermost)[:config]
        status = options[:config][:status][:general]
        circuit = options[:circuit]
        begin
          uri = URI.parse("#{config[:url]}/hooks/#{config[:token]}")
          message = "notifying for circuit #{circuit}, state : #{status}."
          if Sc4ry::Helpers.verify_service url: config[:url]
            request = ::Net::HTTP::Post.new(uri)
            request.content_type = 'application/json'
            req_options = {
              use_ssl: uri.scheme == 'https'
            }
            payload = { 'text' => "message : #{message} from #{Socket.gethostname}", 'username' => 'Sc4ry' }
            Sc4ry::Helpers.log level: :debug, message: "Mattermost Notifying : #{message}"
            request.body = ::JSON.dump(payload)
            ::Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
              http.request(request)
            end

          else
            Sc4ry::Helpers.log level: :warn, message: "Mattermost Notifier : can't notify Mattermost not reachable."
          end
        rescue URI::InvalidURIError
          Sc4ry::Helpers.log level: :warn, message: 'Mattermost Notifier : URL malformed'
        end
      end
    end
  end
end

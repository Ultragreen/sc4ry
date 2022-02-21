
module Sc4ry
  module Helpers

    def Helpers.log(options)
      Sc4ry::Logger.current = options[:target] if options[:target]
      Sc4ry::Logger.get.send options[:level], "Sc4ry : #{options[:message]}"  
    end

    # TCP/IP service checker
    # @return [Bool] status
    # @param [Hash] options
    # @option options [String] :host hostname
    # @option options [String] :port TCP port
    # @option options [String] :url full URL, priority on :host and :port
    def Helpers.verify_service(options ={})
      begin
        if options[:url] then
          uri = URI.parse(options[:url])
          host = uri.host
          port = uri.port
        else
          host = options[:host]
          port = options[:port]
        end
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new(host, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
        return false
      end
    end


    def Helpers.notify(options = {})
      Sc4ry::Notifiers.list.each do |record|
        notifier = Sc4ry::Notifiers.get name: record
        notifier[:class].notify(options) if options[:config][:notifiers].include? record 
      end
    end

  end 
end
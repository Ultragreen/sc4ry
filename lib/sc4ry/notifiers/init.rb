Dir[File.dirname(__FILE__) + '/*.rb'].sort.each { |file| require file unless File.basename(file) == 'init.rb' }

module Sc4ry 
  module Notifiers
    @@notifiers_list = {:prometheus => {:class => Sc4ry::Notifiers::Prometheus, :config => {:url => 'http://localhost:9091'}},
                        :mattermost => {:class => Sc4ry::Notifiers::Mattermost, :config => {:url => 'http://localhost:9999', :token => "<CHANGE_ME>"}}                            
                       }

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
end


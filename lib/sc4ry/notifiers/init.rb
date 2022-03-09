Dir[File.dirname(__FILE__) + '/*.rb'].sort.each { |file| require file unless File.basename(file) == 'init.rb' }

module Sc4ry 
  module Notifiers

    DEFAULT_NOTIFIERS = {:prometheus => {:class => Sc4ry::Notifiers::Prometheus, :config => {:url => 'http://localhost:9091'}},
                          :mattermost => {:class => Sc4ry::Notifiers::Mattermost, :config => {:url => 'http://localhost:9999', :token => "<CHANGE_ME>"}}
                        }
    @@notifiers_list =  DEFAULT_NOTIFIERS.dup                           
  

    def Notifiers.display_config(notifier: )
      raise Sc4ry::Exceptions::Sc4ryNotifierError, "Notifier #{notifier} not found" unless @@notifiers_list.include? notifier
      return @@notifiers_list[notifier][:config]
    end

    def Notifiers.list
      return @@notifiers_list.keys
    end

    def Notifiers.get(name: )
      return @@notifiers_list[name]
    end

    def Notifiers.register(name: , definition: )
      @@notifiers_list[name] = definition
    end

    def Notifiers.config(name:, config: )
      @@notifiers_list[name][:config] = config
      return config
    end
 end
end


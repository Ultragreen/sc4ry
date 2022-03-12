Dir[File.dirname(__FILE__) + '/*.rb'].sort.each { |file| require file unless File.basename(file) == 'init.rb' }

# Sc4ry module
# @note namespace
module Sc4ry 

  # Sc4ry::Notifiers module 
  # @note namespace 
    module Notifiers

    # default notifiers specifications
    DEFAULT_NOTIFIERS = {:prometheus => {:class => Sc4ry::Notifiers::Prometheus, :config => {:url => 'http://localhost:9091'}},
                          :mattermost => {:class => Sc4ry::Notifiers::Mattermost, :config => {:url => 'http://localhost:9999', :token => "<CHANGE_ME>"}}
                        }
    @@notifiers_list =  DEFAULT_NOTIFIERS.dup                           
  
    # class method how display a specific notifier config
    # @param notifier [Symbol] a notifier name
    # @return [Hash] the config                     
    def Notifiers.display_config(notifier: )
      raise Sc4ry::Exceptions::Sc4ryNotifierError, "Notifier #{notifier} not found" unless @@notifiers_list.include? notifier
      return @@notifiers_list[notifier][:config]
    end

    # class method how return the list of known notifiers
    # @return [Array] a list of [Symbol] notifiers name
    def Notifiers.list
      return @@notifiers_list.keys
    end

    # class method how return a specific notifier by name
    # @param name [Symbol] a notifier name
    # @return [Hash] the notifier structure                     
    def Notifiers.get(name: )
      return @@notifiers_list[name]
    end

    # class method how register a specific notifier 
    # @param name [Symbol] a notifier name
    # @param definition [Hash] a notifier definition 
    # @return [Hash] the notifier structure                     
    def Notifiers.register(name: , definition: )
      @@notifiers_list[name] = definition
    end

    
    # class method how configure a specific notifier 
    # @param name [Symbol] a notifier name
    # @param config [Hash] a notifier config  
    # @return [Hash] the notifier structure                     
    def Notifiers.config(name:, config: )
      @@notifiers_list[name][:config] = config
      return config
    end
 end
end


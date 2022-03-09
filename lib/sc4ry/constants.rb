module Sc4ry
    module Constants

        CURRENT_NOTIFIERS = [:prometheus, :mattermost]
        DEFAULT_CONFIG = { 
            :max_failure_count => 5,
            :timeout_value => 20,
            :timeout => false,
            :max_timeout_count => 5,
            :max_time => 10,
            :max_overtime_count => 3,
            :check_delay => 30,
            :notifiers => [],
            :forward_unknown_exceptions => true,
            :raise_on_opening => false,
            :exceptions => [StandardError, RuntimeError]
            }

        DEFAULT_CONFIG_FORMATS = { 
            :max_failure_count => {:proc => Proc::new {|item| item.class == Integer}, :desc => "must be an Integer"}, 
            :timeout_value => {:proc => Proc::new {|item| item.class == Integer}, :desc => "must be an Integer"},
            :timeout => {:proc => Proc::new {|item| [true,false].include? item}, :desc => "must be a Boolean"},
            :max_timeout_count => {:proc => Proc::new {|item| item.class == Integer}, :desc => "must be an Integer"},
            :max_time => {:proc => Proc::new {|item| item.class == Integer}, :desc => "must be an Integer"},
            :max_overtime_count => {:proc => Proc::new {|item| item.class == Integer}, :desc => "must be an Integer"},
            :check_delay => {:proc => Proc::new {|item| item.class == Integer}, :desc => "must be an Integer"},
            :notifiers => {
                :proc => Proc::new {|item| 
                  item.class == Array and item.select {|val|  val.class == Symbol }.size == item.size
                  }, 
                :desc => "must be an Array of Symbol",
                :list => CURRENT_NOTIFIERS},
            :forward_unknown_exceptions => {:proc => Proc::new {|item| [true,false].include? item}, :desc => "must be a Boolean"},
            :raise_on_opening => {:proc => Proc::new {|item| [true,false].include? item}, :desc => "must be a Boolean"},
            :exceptions => {
                :proc => Proc::new {|item| item.class == Array and item.select {|val|  
                    [Class,String].include? val.class}.size == item.size
                }, 
                :desc => "must be an Array of Exception(Class) or String"}
            }

    end
end
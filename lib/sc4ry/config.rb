module Sc4ry
    module Config
        class Validator
            attr_reader :definition
            attr_reader :default
            
            def result
                @default
            end
            
            include Sc4ry::Constants
            include Sc4ry::Exceptions
            
            def initialize(definition: , from: DEFAULT_CONFIG)
                @default = from
                @definition = definition
            end
            
            def validate!
                unknown_keys = @definition.keys.difference @default.keys
                raise ConfigError::new("Unknown keys in config set : #{unknown_keys.to_s}") unless unknown_keys.empty?
                validate_formats
                @default.merge! @definition 
                format_exceptions
            end
            
            private
            def validate_formats
                definition.each do |spec,value|
                    raise ConfigError::new("#{spec} value #{DEFAULT_CONFIG_FORMATS[spec][:desc]}") unless DEFAULT_CONFIG_FORMATS[spec][:proc].call(value)
                    if DEFAULT_CONFIG_FORMATS[spec].include? :list then
                        value.each do |item|
                            raise ConfigError::new("#{spec} value must be in #{DEFAULT_CONFIG_FORMATS[spec][:list]}") unless DEFAULT_CONFIG_FORMATS[spec][:list].include? item
                        end
                    end
                end
            end
            
            def format_exceptions
                @default[:exceptions].map! {|item| item = (item.class == String)? Object.const_get(item) : item  }
            end
            
        end

        class ConfigMapper

            include Sc4ry::Constants
            attr_reader :config
            
            def initialize(definition: DEFAULT_CONFIG)
                @config = definition
                @config.each do |key,value|
                    self.define_singleton_method "#{key.to_s}=".to_sym do |val|
                        key = __method__.to_s.chop.to_sym
                        @config[key]=val
                    end
                    self.define_singleton_method key do 
                        return @config[__method__]
                    end
                end
            end
        end

    end
end
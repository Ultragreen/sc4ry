# Sc4ry module 
# @note namespace
module Sc4ry
    # Sc4ry::Config module
    # @note namespace
    module Config
        # Configuration validator for Sc4ry default and circuits configuration
        # @private
        class Validator

            # accessor on Circuit definition given for validation
            attr_reader :input
            # accessor on circuit initial definition from default config or given in construction by from keyword
            # @note altered by reference to final result mapping with {#validate!}
            attr_reader :config
            
            def result
                @config
            end
            
            include Sc4ry::Constants
            include Sc4ry::Exceptions
            # Validator constructor 
            # @param [Hash] definition the config hash to merge and validate
            # @param [Hash] from config hash merged on origin (default : the Sc4ry base config from Constants )
            # @return [Validator] a new instance of Validator
            def initialize(definition: , from: DEFAULT_CONFIG)
                @config = from
                @input = definition
            end
            
            # Validation method, alter by reference the config attribut
            # @raise ConfigError if un unknown key is given in definition to merge. 
            def validate!
                unknown_keys = @input.keys.difference @config.keys
                raise ConfigError::new("Unknown keys in config set : #{unknown_keys.to_s}") unless unknown_keys.empty?
                validate_formats
                @config.merge! @input 
                format_exceptions
            end
            
            private
            # Validation private sub method 
            # @raise ConfigError if proposed values haven't the good format and deeply in array
            def validate_formats
                @input.each do |spec,value|
                    raise ConfigError::new("#{spec} value #{DEFAULT_CONFIG_FORMATS[spec][:desc]}") unless DEFAULT_CONFIG_FORMATS[spec][:proc].call(value)
                    if DEFAULT_CONFIG_FORMATS[spec].include? :list then
                        value.each do |item|
                            raise ConfigError::new("#{spec} value must be in #{DEFAULT_CONFIG_FORMATS[spec][:list]}") unless DEFAULT_CONFIG_FORMATS[spec][:list].include? item
                        end
                    end
                end
            end
            
            # adapter for exception key in config String to Constant Class Name if need
            # @note by reference
            def format_exceptions
                @config[:exceptions].map! {|item| item = (item.class == String)? Object.const_get(item) : item  }
            end
            
        end

        # Config Data mapper for block yielding methods for configuration 
        # @note work for/with {Sc4ry::Circuits.configure} and {Sc4ry::Circuits.register} when block given
        class ConfigMapper

            include Sc4ry::Constants

            # config from given definition passed in constructor
            attr_reader :config
            
            # the mapping constructor from a given definition or the default From Sc4ry config (Constant)
            # @param [Hash] definition a config hash 
            # @note creating dynamically accessors on config record given in definition
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
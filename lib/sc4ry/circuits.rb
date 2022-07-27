# Sc4ry Module
# @note namespace
module Sc4ry
  # Circuits and default configuration management class
  class Circuits
    include Sc4ry::Constants
    include Sc4ry::Exceptions

    @@circuits_store = Sc4ry::Store.instance
    @@circuits_notifiers = Sc4ry::Notifiers
    @@circuits_loggers = Sc4ry::Loggers
    @@config = DEFAULT_CONFIG

    # @!group forwarders

    # Class method how forward the Notifiers class factory/manager
    # @return [Sc4ry::Notifiers]
    def self.notifiers
      @@circuits_notifiers
    end

    # Class method how forward a Store manager class singleton
    # @return [Sc4ry::Store]
    def self.store
      @@circuits_store
    end

    # Class method how forward the Logger manager class factory/manager
    # @return [Sc4ry::Store]
    def self.loggers
      @@circuits_loggers
    end

    # @!endgroup

    # @!group Default Sc4ry configuration management

    # Class method how return de default Sc4ry config
    # @return [Hash]
    def self.default_config
      @@config
    end

    # class method how merge a differential hash to default config
    # @param [Hash] diff the differential hash config
    # @example usage
    #   include Sc4ry
    #   Circuits.merge_default_config diff: {max_time: 20, notifiers: [:mattermost]}
    def self.merge_default_config(diff:)
      validator = Sc4ry::Config::Validator.new(definition: diff, from: @@config)
      validator.validate!
      @@config = validator.result
    end

    # class method for specifiying config by block
    # @yield [Sc4ry::Config::ConfigMapper]
    # @example usage
    #   include Sc4ry
    #   Circuits.configure do |spec|
    #      spec.max_failure_count = 3
    #   end
    def self.configure
      mapper = Sc4ry::Config::ConfigMapper.new(definition: @@config.dup)
      yield(mapper)
      validator = Sc4ry::Config::Validator.new(definition: mapper.config, from: @@config)
      validator.validate!
      @@config = validator.result
    end

    # old default config setter
    # @deprecated use {.merge_default_config} instead
    # @param [Hash] config
    def self.default_config=(config)
      warning_mess = 'DEPRECATED: Circuits.default_config= use Circuits.merge_default_config add: {<config_hash>}'
      Sc4ry::Helpers.log level: :warn,
                         message: warning_mess
      Circuits.merge_default_config(diff: config)
    end

    # @!endgroup

    # @!group Circuits management

    # class method for registering a new circuit, cloud work with a block
    # @yield [Sc4ry::Config::ConfigMapper]
    # @param [Symbol] circuit a circuit name
    # @param [Hash] config a config override on default config for the circuit
    # @example usage
    #   include Sc4ry
    #   Circuits.register circuit: :mycircuit, config: {raise_on_opening: true, timeout: true}
    #   # or
    #   Circuits.register circuit: :mycircuit do |spec|
    #     spec.raise_on_opening = true
    #     spec.timeout = true
    #   end
    # @return [Hash] the full config of the circuit after merge on default
    # @raise [Sc4ryGenericError] if use config keyword with a block
    # @raise [Sc4ryGenericError] if circuit already exist in current store.
    def self.register(circuit:, config: {})
      if !config.empty? && block_given?
        raise Sc4ryGenericError,
              'config: keyword must not be defined when block is given'
      end

      if block_given?
        mapper = Sc4ry::Config::ConfigMapper.new(definition: @@config.dup)
        yield(mapper)
        validator = Sc4ry::Config::Validator.new(definition: mapper.config, from: @@config.dup)
      else
        validator = Sc4ry::Config::Validator.new(definition: config, from: @@config.dup)
      end
      validator.validate!
      Sc4ry::Helpers.log level: :debug, message: "Circuit #{circuit} : registered"
      raise Sc4ryGenericError, "Circuit: #{circuit} already exist in store" if @@circuits_store.exist? key: circuit

      @@circuits_store.put key: circuit, value: validator.result
      validator.result
    end

    # class method how list all circuits in current store
    # @example usage
    #   include Sc4ry
    #   circuits = Circuits.list
    # @return [Array] the list of [Symbol] circuits name
    def self.list
      @@circuits_store.list
    end

    # class method how flush all circuits in current store
    # @example usage
    #   include Sc4ry
    #   Circuits.flush
    # @return [true,false]
    def self.flush
      @@circuits_store.flush
    end

    # class method for unregistering a circuit
    # @param [Symbol] circuit a circuit name
    # @example usage
    #   include Sc4ry
    #   Circuits.unregister circuit: :mycircuit
    # @raise [Sc4ryGenericError] if circuit not found in current store.
    # @return [true,false]
    def self.unregister(circuit:)
      raise Sc4ryGenericError, "Circuit #{circuit} not found" unless Circuits.list.include? circuit

      @@circuits_store.del key: circuit
      Sc4ry::Helpers.log level: :debug, message: "Circuit #{circuit} : unregistered"
      true
    end

    # class method for get a specific circuit by circuit name
    # @param [Symbol] circuit a circuit name
    # @example usage
    #   include Sc4ry
    #   Circuits.get circuit: :mycircuit
    # @return [Hash] the circuit record in current store included values and status if the circuit have already run.
    def self.get(circuit:)
      @@circuits_store.get key: circuit
    end

    # class method for update the config of a specific circuit by circuit name
    # @param [Symbol] circuit a circuit name
    # @param [Hash] config a config hash to merge on current config
    # @example usage
    #   include Sc4ry
    #   Circuits.update_config circuit: :mycircuit, config: {}
    # @note : <b>important</b> updating config will reset status and values !
    # @return [Hash] new config for this circuit
    def self.update_config(circuit:, config: { forward_unknown_exceptions: false })
      raise Sc4ryGenericError, "Circuit #{circuit} not found" unless Circuits.list.include? circuit

      save = @@circuits_store.get key: circuit
      save.delete_if { |key, _val| %i[status values].include? key }
      Circuits.unregister(circuit: circuit)
      save.merge! config
      Circuits.register circuit: circuit, config: save
    end

    # class method for get the status of a specific circuit by circuit name
    # @param [Symbol] circuit a circuit name
    # @example usage
    #   include Sc4ry
    #   Circuits.status circuit: :mycircuit
    # @return [Symbol]  status must in [:open,:half_open,:closed,:never_run]
    def self.status(circuit:)
      data = @@circuits_store.get key: circuit
      data.include?(:status) ? data[:status][:general] : :never_run
    end

    # class method for running circuit, need a block
    # @yield [Proc]
    # @param [Symbol] circuit a circuit name
    # @example usage
    #   include Sc4ry
    #   Circuits.run circuit: :mycircuit do
    #       #  [...]  your code like a Restclient.get("URL")
    #   end
    #   # or
    #   Circuits.run do
    #        # [...] your code like a Restclient.get("URL")
    #        #  running with the first define circuit (use only on a one circuit usage)
    #   end
    # @return [Hash] a result like ":general=>:open, :failure_count=>X, :overtime_count=>X, :timeout_count=>X"
    # @raise [Sc4ryGenericError] if circuit already not exit, block is missing or store empty
    def self.run(circuit: nil, &block)
      circuits_list = Circuits.list
      raise Sc4ryGenericError, 'No circuit block given' unless block_given?
      raise Sc4ryGenericError, 'No circuits defined' if circuits_list.empty?

      circuit_name = circuit || circuits_list.first
      raise Sc4ryGenericError, "Circuit #{circuit_name} not found" unless circuits_list.include? circuit_name

      circuit_to_run = Circuits.get circuit: circuit_name
      skip = false
      if circuit_to_run.include?(:status) && (circuit_to_run[:status][:general] == :open)
        @now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        skip = true if (@now - circuit_to_run[:values].last[:end_time]) < circuit_to_run[:check_delay]
      end
      unless skip
        controller = Sc4ry::RunController.new(circuit_to_run)
        Circuits.control circuit: circuit_name, values: controller.run(block: block)
      end
      result = @@circuits_store.get key: circuit_name
      Sc4ry::Helpers.log level: :debug, message: "Circuit #{circuit_name} : status #{result[:status]}"
      result
    end

    # @!endgroup

    # the private class method to control circuits running status
    # @param [Symbol] circuit the name the circuit to control
    # @param [Hash] values the resut value of a run
    # @return [Boolean]
    def self.control(circuit:, values:)
      data = @@circuits_store.get key: circuit
      unless data.include? :status
        data[:status] =
          { general: :closed, failure_count: 0, overtime_count: 0, timeout_count: 0 }
      end
      data[:values] = [] unless data.include? :values
      level = [data[:max_failure_count].to_i, data[:max_timeout_count].to_i, data[:max_overtime_count].to_i].max
      data[:values].shift if data[:values].size > level
      data[:values].push values
      worst_status = []
      %w[failure overtime timeout].each do |control|
        if values[control.to_sym] == true
          data[:status]["#{control}_count".to_sym] += 1
        else
          data[:status]["#{control}_count".to_sym] = 0
        end

        case data[:status]["#{control}_count".to_sym]
        when 0
          worst_status.push :closed
        when 1..data["max_#{control}_count".to_sym]
          worst_status.push :half_open
        else
          worst_status.push :open
        end
      end
      save = data[:status][:general]
      %i[closed half_open open].each do |status|
        data[:status][:general] = status if worst_status.include? status
      end
      if save != data[:status][:general]
        raise CircuitBreaked if data[:status][:general] == :open && data[:raise_on_opening]

        if data[:status][:general] == :open
          Sc4ry::Helpers.log level: :error,
                             message: "Circuit #{circuit} : breacking ! "
        end
        if data[:status][:general] == :closed
          Sc4ry::Helpers.log level: :info,
                             message: "Circuit #{circuit} : is now closed"
        end
        Sc4ry::Helpers.notify circuit: circuit, config: data
      end
      @@circuits_store.put key: circuit, value: data
    end
  end
end

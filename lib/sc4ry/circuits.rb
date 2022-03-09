module Sc4ry
  class Circuits

    include Sc4ry::Constants
    include Sc4ry::Exceptions

    @@circuits_store = Sc4ry::Store.instance 

    @@config = DEFAULT_CONFIG

    def Circuits.default_config
      return @@config
    end

    def Circuits.merge_default_config(diff:)
      validator = Sc4ry::Config::Validator::new(definition: diff, from: @@config)
      validator.validate!
      @@config = validator.result 

    end

    def Circuits.configure(&bloc)
      mapper = Sc4ry::Config::ConfigMapper::new(definition: @@config.dup)
      yield(mapper)
      validator = Sc4ry::Config::Validator::new(definition: mapper.config, from: @@config)
      validator.validate!
      @@config = validator.result 
    end


    def Circuits.default_config=(config)
      Sc4ry::Helpers.log level: :warn, message: "DEPRECATED: Circuits.default_config= is deprecated please use Circuits.merge_default_config add: {<config_hash>}"
      Circuits.merge_default_config(diff: config)
    end

    def Circuits.register(circuit:, config: {})
      if config.size > 0 and block_given? then 
        raise Sc4ryGenericError, "config: keyword must not be defined when block is given"
      end
      if block_given? then 
        mapper = Sc4ry::Config::ConfigMapper::new(definition: @@config.dup)
        yield(mapper)
        validator = Sc4ry::Config::Validator::new(definition: mapper.config, from: @@config.dup)
      else 
        validator = Sc4ry::Config::Validator::new(definition: config, from: @@config.dup )
      end
      validator.validate!
      Sc4ry::Helpers.log level: :debug, message: "Circuit #{circuit} : registered"
      @@circuits_store.put key: circuit, value: validator.result 
    end

    def Circuits.list
      return @@circuits_store.list
    end


    def Circuits.get(options)
      @@circuits_store.get key: options[:circuit]
    end

    def Circuits.run(options = {}, &block)
      circuits_list = Circuits.list
      raise Sc4ryGenericError, "No circuit block given" unless block_given?
      raise Sc4ryGenericError, "No circuits defined" if circuits_list.empty? 
      circuit_name = (options[:circuit])? options[:circuit] : circuits_list.first
      raise Sc4ryGenericError, "Circuit #{circuit_name} not found" unless circuits_list.include? circuit_name
      circuit = Circuits.get circuit: circuit_name
      skip = false
      if circuit.include? :status then
        if circuit[:status][:general] == :open then 
          @now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          skip = true if ((@now - circuit[:values].last[:end_time]) <  circuit[:check_delay])
        end
      end
      unless skip 
        controller = Sc4ry::RunController.new(circuit)
        Circuits.control circuit: circuit_name, values: controller.run(block: block)
      end
      Sc4ry::Helpers.log level: :debug, message: "Circuit #{circuit_name} : status #{circuit[:status]}"

    end

    private
    def Circuits.control(options={})
      data = @@circuits_store.get key: options[:circuit]
      data[:status] = {:general => :closed, :failure_count => 0, :overtime_count => 0, :timeout_count => 0} unless data.include? :status
      data[:values] = Array::new unless data.include? :values
      level = [data[:max_failure_count].to_i, data[:max_timeout_count].to_i, data[:max_overtime_count].to_i].max
      data[:values].shift if data[:values].size > level
      data[:values].push options[:values]
      worst_status = []
      ['failure','overtime','timeout'].each do |control|
        if options[:values][control.to_sym] == true then
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
      [:closed,:half_open,:open].each do |status|
        data[:status][:general] = status if worst_status.include? status
      end
      if save != data[:status][:general] then
        raise CircuitBreaked if data[:status][:general] == :open and data[:raise_on_opening]
        Sc4ry::Helpers.log level: :error, message: "Circuit #{options[:circuit]} : breacking ! " if data[:status][:general] == :open
        Sc4ry::Helpers.log level: :info, message: "Circuit #{options[:circuit]} : is now closed" if data[:status][:general] == :closed
        Sc4ry::Helpers.notify circuit: options[:circuit], config: data 
      end          
      @@circuits_store.put key: options[:circuit], value: data
    end
  end
end
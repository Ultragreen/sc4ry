module Sc4ry
  class Circuits

    @@circuits_store = Sc4ry::Store.instance 

    @@config = { :max_failure_count => 5,
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

    def Circuits.default_config
      return @@config
    end

    def Circuits.default_config=(config)
      @@config = config
    end

    def Circuits.register(options = {})
      raise ":circuit is mandatory" unless options[:circuit]
      name = options[:circuit]
      override = (options[:config].class == Hash)? options[:config] : {}
      config = @@config.merge override
      @@circuits_store.put key: name, value: config 
    end

    def Circuits.list
      return @@circuits_store.list
    end


    def Circuits.get(options)
      @@circuits_store.get key: options[:circuit]
    end

    def Circuits.run(options = {}, &block)
      circuits_list = Circuits.list
      raise "No circuit block given" unless block_given?
      raise "No circuits defined" if circuits_list.empty? 
      circuit_name = (options[:circuit])? options[:circuit] : circuits_list.first
      raise "Circuit #{circuit_name} not found" unless circuits_list.include? circuit_name
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
      Sc4ry::Helpers.log level: :info, message: "Circuit #{circuit_name} : status #{circuit[:status]}"

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
        raise Sc4ry::Exceptions::CircuitBreaked if data[:status][:general] == :open and data[:raise_on_opening]
        Sc4ry::Helpers.notify circuit: options[:circuit], config: data 
      end          
      @@circuits_store.put key: options[:circuit], value: data
    end
  end
end


RSpec.describe Sc4ry do

  before :all do 
    $log_file = '/tmp/logfile.log'
    File::unlink($log_file) if File::exist?($log_file)
    $base_config_store_redis = {:host => 'localhost', :port => 6379, :db => 10}
    $default_config_store_redis = $base_config_store_redis.dup
    $default_config_store_redis[:host] = (ENV["REDIS_HOST"])? ENV["REDIS_HOST"] : "localhost"
    $default_config_store_redis[:port] = (ENV["REDIS_PORT"])? ENV["REDIS_PORT"] : 6379
    $pushgateway = Hash::new
    $pushgateway[:port] = (ENV["PROM_PG_PORT"])? ENV["PROM_PG_PORT"] :  9091
    $pushgateway[:host] = (ENV["PROM_PG_HOST"])? ENV["PROM_PG_HOST"] :  'localhost'

    $default_config ={
      :max_failure_count=>5,
      :timeout_value=>20,
      :timeout=>false,
      :max_timeout_count=>5,
      :max_time=>10,
      :max_overtime_count=>3,
      :check_delay=>30,
      :notifiers=>[],
      :forward_unknown_exceptions=>true,
      :raise_on_opening=>false,
      :exceptions=>[StandardError, RuntimeError]}

      $testing_config ={
        :max_failure_count=>3,
        :timeout_value=>2,
        :timeout=>false,
        :max_timeout_count=>2,
        :max_time=>1,
        :max_overtime_count=>2,
        :check_delay=>3,
        :notifiers=>[],
        :forward_unknown_exceptions=>true,
        :raise_on_opening=>false,
        :exceptions=>[StandardError, RuntimeError]}
      $update_by_merge =  $default_config.dup
      $update_by_merge[:max_time] = 12
      $update_by_block  = $update_by_merge.dup
      $update_by_block[:check_delay] = 30
      unless ENV["REDIS_HOST"] then
        Sc4ry::Circuits.store.change_backend name: :redis
        Sc4ry::Circuits.store.flush
        Sc4ry::Circuits.store.change_backend name: :memory
      end
    end

  after :all do 
    # File::unlink($log_file) if File::exist?($log_file)
  end

  subject { Sc4ry }
  it { should be_an_instance_of Module}
  context "Sc4ry::Circuits" do
    subject { Sc4ry::Circuits }
    it { should be_an_instance_of Class }
  end


  it "has a version number" do
    expect(Sc4ry::VERSION).not_to be nil
  end

  context  "Configuration" do 
    it "must be possible to get the default configuration with Sc4ry::Circuits.default_config" do 
      expect(Sc4ry::Circuits.default_config).to eq $default_config
    end

    it "must be possible to get the merge hash to default configuration with Sc4ry::Circuits.merge_default_config" do 
      expect(Sc4ry::Circuits.merge_default_config diff: {max_time: 12}).to eq $update_by_merge
    end

    it "must be possible to modify the default configuration by block on Sc4ry::Circuits.configure" do 
      Sc4ry::Circuits.configure do |spec|
        spec.check_delay = 30
      end
      expect(Sc4ry::Circuits.default_config).to eq $update_by_block
    end
    it "New default Configuration must be update compositly by the two methods" do 
      expect(Sc4ry::Circuits.default_config).to eq $update_by_block
    end
    it "trying to add an unknown key by merge must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.merge_default_config diff: {maxi_time: 12}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end
    it "trying to add an existing key but in an incorrect format must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.merge_default_config diff: {max_time: "STRING"}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end
    it "trying to add an existing key but DEEPLY in an incorrect format must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.merge_default_config diff: {notifiers: ["STRING"]}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end
    it "trying to add an existing key (Array) but with an unknown value  must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.merge_default_config diff: {notifiers: [:mattermost, :twitter]}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end
  end

  context  "Registering a circuit" do 
    it "must possible to register a circuit with default config with Sc4ry::Circuits.register" do 
      expect(Sc4ry::Circuits.register circuit: :test1).to eq $update_by_block
    end

    it "must possible to register a circuit with override config with Sc4ry::Circuits.register by merge" do 
      $config_test2 = $update_by_block.dup 
      $config_test2[:max_failure_count] = 10
      expect(Sc4ry::Circuits.register circuit: :test2, config: {max_failure_count: 10}).to eq $config_test2
    end

    it "must possible to register a circuit with override config with Sc4ry::Circuits.register by block" do 
      $config_test3 = $update_by_block.dup 
      $config_test3[:max_failure_count] = 12
      expect(Sc4ry::Circuits.register(circuit: :test3) {|spec| spec.max_failure_count = 12}).to eq $config_test3
    end

    it "must be possible to get circuit list with Sc4ry::Circuits::list" do 
      expect(Sc4ry::Circuits.list.sort).to eq [:test1, :test2, :test3] 
    end

    it "muts validate required config for each circuit with Sc4ry::Circuits.get" do 
      {test1: $update_by_block, test2:$config_test2, test3: $config_test3}.each do |test, config|
        expect(Sc4ry::Circuits.get circuit: test).to eq config
      end 
    end 

    it "trying to register circuit with an unknown key by merge must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.register circuit: :test4, config: {maxi_time: 12}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end
    it "trying to register circuit with an existing key but in an incorrect format must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.register circuit: :test4, config: {max_time: "STRING"}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end
    it "trying to register circuit with an existing key but DEEPLY in an incorrect format must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.register circuit: :test4, config: {notifiers: ["STRING"]}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end
    it "trying to register circuit with an existing key (Array) but with an unknown value  must raise an exception Sc4ry::Exceptions::ConfigError" do 
      expect{Sc4ry::Circuits.register circuit: :test4, config: {notifiers: [:mattermost, :twitter]}}.to raise_error(Sc4ry::Exceptions::ConfigError)
    end

  end

  context "Sc4ry::Logger" do
    subject { Sc4ry::Loggers }
    it { should be_an_instance_of Class }
  end

  context "Logging" do 

    it "must be possible to check there is one default loggers with Sc4ry::Logger.current and Sc4ry::Loggers.list_available" do 
      expect(Sc4ry::Loggers.current).to eq :stdout
      expect(Sc4ry::Loggers.list_available).to eq [:stdout]
    end

    it "must be possible to register a logger with Sc4ry::Logger.register" do 
      expect(Sc4ry::Loggers.register name: :test_logger, instance: ::Logger.new($log_file) ).to eq :test_logger
    end


    it "must be possible to get the list of configured loggers with Sc4ry::Logger.list_available" do 
      expect(Sc4ry::Loggers.list_available.sort).to eq [:stdout, :test_logger]
    end

    it "trying to register a logger without symbol as name must raise an exception Sc4ry::Exceptions::Sc4ryGenericError" do 
      expect{Sc4ry::Loggers.register name: "test_logger", instance: ::Logger.new($log_file) }.to raise_error(Sc4ry::Exceptions::Sc4ryGenericError)
    end

    it "trying to register a logger without name must raise an exception ArgumentError" do 
      expect{Sc4ry::Loggers.register instance: ::Logger.new($log_file) }.to raise_error(ArgumentError)
    end

    it "trying to register a logger without instance must raise an exception ArgumentError" do 
      expect{Sc4ry::Loggers.register name: :test }.to raise_error(ArgumentError)
    end

    it "must be possible to get the current  loggers with Sc4ry::Logger.current" do 
      expect(Sc4ry::Loggers.current).to eq :stdout
    end

    it "must be possible to set the current logger with Sc4ry::Logger.current= " do 
      expect(Sc4ry::Loggers.current = :test_logger).to eq :test_logger
    end

    it "must be possible to verify the current logger with Sc4ry::Logger.current" do 
      expect(Sc4ry::Loggers.current).to eq :test_logger
    end

    it "must be possible to get the current logger with Sc4ry::Logger.get" do
      expect(Sc4ry::Loggers.get).to be_a Logger
    end

    it "must write to file #{$log_file} when register a circuit" do 
      Sc4ry::Circuits.register circuit: :test4
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test4 : registered/).size).to eq 1
    end
  end

  context "Sc4ry::Store" do
    subject { Sc4ry::Store }
    it { should be_an_instance_of Class }
  end

  context "Store" do 
    it "must be possible to display the current Store Backend with Sc4ry::Circuits.store.current" do
      expect(Sc4ry::Circuits.store.current).to eq :memory
    end 
    it "must be possible to list all available Store Backend with Sc4ry::Circuits.store.list_backend" do
      expect(Sc4ry::Circuits.store.list_backend.sort).to eq [:memory,:redis]
    end 
    it "must be possible to display current config of redis backend with Sc4ry::Circuits.store.get_config" do
      expect(Sc4ry::Circuits.store.get_config backend: :redis).to eq $base_config_store_redis
    end 

    it "must be possible to change current config of redis backend with Sc4ry::Circuits.store.config_backend" do
      $change_config = $default_config_store_redis.dup
      $change_config[:db] = 11
      Sc4ry::Circuits.store.config_backend name: :redis, config: $change_config
      expect(Sc4ry::Circuits.store.get_config backend: :redis).to eq $change_config
      Sc4ry::Circuits.store.config_backend name: :redis, config: $default_config_store_redis
      expect(Sc4ry::Circuits.store.get_config backend: :redis).to eq $default_config_store_redis
    end

    it "must be possible to switch current backend with Sc4ry::Circuits.store.change_backend" do 
      expect(Sc4ry::Circuits.store.change_backend name: :redis).to eq :redis
    end

    it "have reset circuits list" do 
      expect(Sc4ry::Circuits.list).to eq [] 
    end

    it "must be possible to register a circuit with override config with Sc4ry::Circuits.register by merge" do 
      expect(Sc4ry::Circuits.register circuit: :test, config: $testing_config.dup.freeze).to eq $testing_config
    end
    
  end


  context "Running circuit & failure" do 

    it "must be possible to check if circuit have never run with Sc4ry::Circuits.status" do
      expect(Sc4ry::Circuits.status circuit: :test).to eq :never_run
    end

    it "must running circuit without error" do 
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit"
      end
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test : status {:general=>:closed, :failure_count=>0, :overtime_count=>0, :timeout_count=>0}/).size).to eq 1
    end

    it "must running circuit with error controlled by Sc4ry StandardError" do 
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit with error"
        raise StandardError
      end
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test : status {:general=>:half_open, :failure_count=>1, :overtime_count=>0, :timeout_count=>0}/).size).to eq 1
    end

    it "trying to run circuit with an uncovered Exception must forward this exception if config[:forward_unknown_exceptions] == true" do 
      expect{ 
        Sc4ry::Circuits.run circuit: :test do
          Sc4ry::Helpers.log level: :info, message: "running circuit with error uncovered"
          raise Sc4ry::Exceptions::Sc4ryGenericError
        end
      }.to raise_error(Sc4ry::Exceptions::Sc4ryGenericError)
    end

    it "must be possible to check the circuit is half_open with Sc4ry::Circuits.status" do
      expect(Sc4ry::Circuits.status circuit: :test).to eq :half_open
    end

    it "must running circuit 3 more times (>3 times at all) with error controlled by Sc4ry StandardErro to open circuit" do 
      3.times do
        Sc4ry::Circuits.run circuit: :test do
          Sc4ry::Helpers.log level: :info, message: "running circuit with error"
          raise StandardError
        end
      end
      expect(open($log_file).grep(/ERROR -- : Sc4ry : Circuit test : breacking !/).size).to eq 1      
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test : status {:general=>:open, :failure_count=>4, :overtime_count=>0, :timeout_count=>0}/).size).to eq 1
    end

    it "must be possible to check the circuit is open with Sc4ry::Circuits.status" do
      expect(Sc4ry::Circuits.status circuit: :test).to eq :open
    end

    it "must stay open for > 3 secondes also if running without errors as it configured config[:check_delay]= 3" do 
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit"
      end
      expect(Sc4ry::Circuits.status circuit: :test).to eq :open
    end

    it "trying to re-running without errors after 3 secondes re closed the circuit" do 
      sleep 3
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit"
      end
      expect(Sc4ry::Circuits.status circuit: :test).to eq :closed
      expect(open($log_file).grep(/INFO -- : Sc4ry : Circuit test : is now closed/).size).to eq 1 
    end

  end
  
  context "Running circuit & overtime " do 
    it "must running circuit > 2 times (config[:max_overtime_count]) more than config[:max_time] = 1 to open circuit" do 
      3.times do
        Sc4ry::Circuits.run circuit: :test do
          Sc4ry::Helpers.log level: :info, message: "running circuit with error"
          sleep 2
        end
      end
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test : status {:general=>:half_open, :failure_count=>0, :overtime_count=>\d+, :timeout_count=>0}/).size).to eq 2
      expect(open($log_file).grep(/ERROR -- : Sc4ry : Circuit test : breacking !/).size).to eq 2      
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test : status {:general=>:open, :failure_count=>0, :overtime_count=>3, :timeout_count=>0}/).size).to eq 1
      expect(Sc4ry::Circuits.status circuit: :test).to eq :open
    end
  end

  context "Running circuit & timeout" do 
    it "must be possible to reconfigure a circuit with  Circuits.update_config by merge" do 
      $testing_config[:timeout] = true
      
      expect(Sc4ry::Circuits.update_config circuit: :test, config: $testing_config).to eq $testing_config
    end
       
    it "must be possible to reconfigure a circuit with  Circuits.update_config by merge partial " do 
      $testing_config[:max_timeout_count] = 1
      $testing_config[:max_time] = 5
      expect(Sc4ry::Circuits.update_config(circuit: :test, config: {max_time: 5, max_timeout_count: 1})).to eq $testing_config
    end

    it "must validate config for test circuit with Sc4ry::Circuits.get" do 
      $testing_config[:exceptions].map!{|item| item = Object.const_get(item) if item.class == String }
      expect(Sc4ry::Circuits.get circuit: :test).to eq $testing_config
    end 

    it "must running circuit 1 more times (>1 times at all)on timeout (2s) conforming to config to open circuit" do 
      2.times do
        Sc4ry::Circuits.run circuit: :test do
          Sc4ry::Helpers.log level: :info, message: "running circuit with error"
          sleep 3
        end
      end
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test : status {:general=>:half_open, :failure_count=>0, :overtime_count=>0, :timeout_count=>\d+}/).size).to eq 1
      expect(open($log_file).grep(/ERROR -- : Sc4ry : Circuit test : breacking !/).size).to eq 3      
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Circuit test : status {:general=>:open, :failure_count=>0, :overtime_count=>0, :timeout_count=>2}/).size).to eq 1
    end


  end

  context "Running circuit raise on opening" do 

    it "trying to re-running without errors after 3 secondes re closed the circuit" do 
      sleep 3
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit"
      end
      expect(Sc4ry::Circuits.status circuit: :test).to eq :closed
      expect(open($log_file).grep(/INFO -- : Sc4ry : Circuit test : is now closed/).size).to eq 2

    end

    it "must be possible to reconfigure a circuit with  Circuits.update_config by merge partial " do 
      $testing_config[:raise_on_opening] = true
      Sc4ry::Circuits.update_config(circuit: :test, config: {raise_on_opening: true})
    end

    it "trying to run circuit with an uncovered Exception must forward this exception if config[:forward_unknown_exceptions] == true" do 
      expect{ 
        4.times do
          Sc4ry::Circuits.run circuit: :test do
            Sc4ry::Helpers.log level: :info, message: "running circuit with error uncovered"
            raise StandardError
        end
      end
      }.to raise_error(Sc4ry::Exceptions::CircuitBreaked)
    end

  end

  context "Notifiers" do 

    it "must possible to get the list of available notifiers with Sc4ry::Circuits.notifiers.list" do 
      expect(Sc4ry::Circuits.notifiers.list.sort ).to eq [:mattermost, :prometheus]
    end

    it "must possible to config  notifiers with Sc4ry::Circuits.notifiers.config" do 
      $prom_config = {url: "http://#{$pushgateway[:host]}:#{$pushgateway[:port]}"}
      expect(Sc4ry::Circuits.notifiers.config name: :prometheus, config: $prom_config).to eq $prom_config
    end

    it "must possible to verify config  notifiers with Sc4ry::Circuits.notifiers.display_config" do 
      expect(Sc4ry::Circuits.notifiers.display_config notifier: :prometheus ).to eq $prom_config
    end

    it "must be possible to reconfigure a circuit with  Circuits.update_config by merge partial " do 
     test_config = {
      :max_failure_count=>1,
      :check_delay=>1,
      :notifiers=>[:prometheus,:mattermost],
      :forward_unknown_exceptions=>false,
      :raise_on_opening=> false, 
      :exceptions=>[StandardError, RuntimeError]}
      Sc4ry::Circuits.update_config(circuit: :test, config: test_config)
    end


    it "must running circuit with error controlled by Sc4ry StandardError to half_open" do 
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit with error"
        raise StandardError
      end
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Prometheus Notifier : notifying for circuit test, state : half_open./).size).to eq 1
    end

    it "must running again circuit with error controlled by Sc4ry StandardError to open" do 
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit with error"
        raise StandardError
      end
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Prometheus Notifier : notifying for circuit test, state : open./).size).to eq 1
    end

    it "trying to re-running without errors after 3 secondes re closed the circuit" do 
      sleep 3
      Sc4ry::Circuits.run circuit: :test do
        Sc4ry::Helpers.log level: :info, message: "running circuit"
      end
      expect(Sc4ry::Circuits.status circuit: :test).to eq :closed
      expect(open($log_file).grep(/INFO -- : Sc4ry : Circuit test : is now closed/).size).to eq 3
      expect(open($log_file).grep(/DEBUG -- : Sc4ry : Prometheus Notifier : notifying for circuit test, state : closed./).size).to eq 1

    end

    it "must trace 3 times failed attempt to notify unconfigured mattermost notifier" do
      expect(open($log_file).grep(/WARN -- : Sc4ry : Mattermost Notifier : URL malformed/).size).to eq 3
    end
  end

  context "Ending : flushing" do
    it "mustbe possible to flush redis backend with Sc4ry::Circuits.store.flush" do
      Sc4ry::Circuits.store.flush
    end
  end

end

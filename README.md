# Sc4ry : Simple CircuitBreacker For RubY

Sc4ry provide the Circuit Breaker Design Pattern for your applications

[![Ruby](https://github.com/Ultragreen/Sc4ry/workflows/Ruby/badge.svg)](https://github.com/Ultragreen/sc4ry/actions?query=workflow%3ARuby+branch%3Amaster)
![GitHub](https://img.shields.io/github/license/Ultragreen/sc4ry)

[![Documentation](https://img.shields.io/badge/docs-rubydoc.info-brightgreen)](https://rubydoc.info/gems/sc4ry)
![GitHub issues](https://img.shields.io/github/issues/Ultragreen/sc4ry)
![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/Ultragreen/sc4ry)
![GitHub top language](https://img.shields.io/github/languages/top/Ultragreen/sc4ry)
![GitHub milestones](https://img.shields.io/github/milestones/open/Ultragreen/sc4ry)

![Gem](https://img.shields.io/gem/dt/sc4ry)
[![Gem Version](https://badge.fury.io/rb/sc4ry.svg)](https://badge.fury.io/rb/sc4ry)
![Twitter Follow](https://img.shields.io/twitter/follow/Ultragreen?style=social)
![GitHub Org's stars](https://img.shields.io/github/stars/Ultragreen?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/Ultragreen/sc4ry?style=social)

<noscript><a href="https://liberapay.com/ruydiaz/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg"></a></noscript>

![Sc4ry logo](assets/images/logo_sc4ry.png) 
_Simple CircuitBreacker 4 RubY_

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sc4ry'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sc4ry

## Usage

### Circuits States Worflow

![Sc4ry workflow](assets/images/sc4ry_workflow.png) 
### Quickstart : sample with Restclient

A quick circuit test :
create a test script lile test.rb :

```ruby

  require 'rubygems'
  require 'sc4ry'

  include Sc4ry

  Circuits.register circuit: :mycircuit, config: {:notifiers => [:prometheus,:mattermost], 
                                                  :exceptions => [Errno::ECONNREFUSED, URI::InvalidURIError]}

  Circuits.run  do # circuit: :mycircuit is optional, run work with the first circuit registered
    puts RestClient.get('http://your_service/endpoint')
  end

  

```

### the Sc4ry Config default values :

Default values, circuit is half open before one of the max count is reached :

* _:max_failure_count_
<br>*description* : maximum failure before opening circuit
<br>*default value* : 5
<br>

*  _:timeout_value_
<br>*description* : timeout value, if :timeout => true
<br>*default value* : 20
<br>

*  _:timeout_
<br>*description* : (de)activate internal timeout
<br>*default value* : false
<br>

*  _:max_timeout_count_
<br>*description* : maximum timeout try before opening circuit
<br>*default value** : 5
<br>

*  _:max_time_
<br>*description* : maximum time for a circuit run
<br>*default value* : 10
<br>

*  _:max_overtime_count_
<br>*description* : maximum count of overtime before opening circuit
<br>*default value* : 3
<br>

*  _:check_delay_
<br>*description* : delay after opening, before trying again to closed circuit or after an other check
<br>*default value* : 30
<br>

*  _:notifiers_
<br>*description* : active notifier, must be :symbol in [:prometheus, :mattermost]
<br>*default value* : []
<br>

*  _:forward_unknown_exceptions_
<br>*description* : (de)activate forwarding of unknown exceptions, just log in DEBUG if false
<br>*default value* : true
<br>

*  _:raise_on_opening_
<br>*description* : (de)activate raise specific Sc4ry exceptions ( CircuitBreaked ) if circuit opening
<br>*default value* : false
<br>

*  _:exceptions_
<br>*description* : [StandardError, RuntimeError]
<br>*default value* : list of selected Exceptions considered for failure, others are SKIPPED.  

### Global overview for all features

This script could be usefull to test all feature on your installation 

You need: 
* Redis 
* Prometheus pushgateway
* an endpoint if you want to check real endpoint
* a Mattermost/Slack incoming webhook (optional)

You could gate all this pre-requistes simply if you jave docker up on your machine

```
    $ docker pull redis:latest
    $ docker run --rm -d  -p 6379:6379/tcp redis:latest
    $ docker pull prom/pushgateway:latest
    $ docker run --rm -d -p 9091:9091 prom/pushgateway:latest
    $ git clone https://github.com/Ultragreen/MockWS.git
    $ cd MockWS
    $ rackup
```

create the test script like :

```ruby

    require 'rubygems'
    require 'sc4ry'


    include Sc4ry

    # display of default Sc4ry config
    puts '1.1/ CONFIG : Initial default config'
    Circuits.default_config.each do |item,value|
      puts " * #{item} : #{value}"
    end
    puts ''

    # testing the two ways to configure Sc4ry default config
    puts "1.2/ CONFIG : modifying default config activate timout and set max_time to 12"
    Circuits.merge_default_config diff: {timeout: true }
    Circuits.configure do |spec|
      spec.max_time = 12
    end
    puts ''

    # display default config, must be override with a nested hash by calling default_config= method
    puts '1.3/ CONFIG : Default config updated:'
    Circuits.default_config.each do |item,value|
      puts " * #{item} : #{value}"
    end
    puts ''

    # display current data Store
    print "2.1/ STORE : Current datastore backend : "
    puts Circuits.store.current
    puts ''


    # display available backend
    puts "2.2/ STORE : List of existing backends : "
    Circuits.store.list_backend.each do |backend|
      puts " - #{backend}"
    end
    puts ''


    # display Redis backend config in store before change
    puts '2.3/ STORE : display default config of redis backend'
    Circuits.store.get_config(backend: :redis).each do |item,value|
      puts " * #{item} : #{value}"
    end
    puts ''

    # reconfigure a backend
    puts "2.4/ STORE : reconfigure Redis backend"
    Circuits.store.config_backend name: :redis, config: {:host => 'localhost', :port => 6379, :db => 10 }
    puts

    # display after
    puts '2.5/ STORE : display altered config of redis backend'
    Circuits.store.get_config(backend: :redis).each do |item,value|
      puts " * #{item} : #{value}"
    end
    puts ''


    # change backend

    puts '2.6/ STORE : change to redis backend (NEED a Redis installed) '
    puts "  $ docker pull redis:latest"
    puts "  $ docker run --rm -d  -p 6379:6379/tcp redis:latest"
    Circuits.store.change_backend name: :redis
    puts ''

    puts '2.7/ STORE : flush redis backend, just for test, and for idempotency (NEED a Redis installed) '
    Circuits.store.flush
    puts ''

    # defining a circuit, config must be empty or override from default
    puts "3.1/ CIRCUIT : registering a circuit by merge :"
    Circuits.register circuit: :test, config: {:notifiers => [:prometheus,:mattermost], :exceptions => [Errno::ECONNREFUSED, URI::InvalidURIError] }
    puts ""

    puts "3.2/ CIRCUIT : registering a circuit by block :"
    Circuits.register circuit: :test2 do |spec|
      spec.exceptions = [Errno::ECONNREFUSED]
    end
    puts ''

    puts "3.3/ CIRCUIT : registering a circuit by default :"
    Circuits.register circuit: :test3
    puts ''

    puts "3.4/ CIRCUITS : Circuits list"
    Circuits::list.each do |circuit|
      puts " * #{circuit}"
    end
    puts ""

    puts "3.5/ CIRCUIT : display a circuit config :test3 :"
    Circuits.get(circuit: :test3).each do |item,value|
      puts " * #{item} : #{value}"
    end
    puts ""

    puts "3.6/ CIRCUIT : update config of :test3 => :raise_on_opening == true  :"
    Circuits.update_config circuit: :test3, config: {raise_on_opening: true}
    puts ''

    puts "3.7/ CIRCUIT : display a circuit config :test3 after change :"
    Circuits.get(circuit: :test3).each do |item,value|
      puts " * #{item} : #{value}"
    end
    puts ""


    puts "3.8/ unregister a circuit : :test2 :"
    Circuits.unregister circuit: :test2
    puts ''

    puts "3.9/ CIRCUITS : Circuits list after unregister"
    Circuits::list.each do |circuit|
      puts " * #{circuit}"
    end
    puts ""

    # Config an alternate logger

    puts "4.1/ LOGGER : register a logger on file "
    Circuits.loggers.register name: :perso, instance: ::Logger.new('/tmp/logfile.log')
    puts ''

    puts "4.2/ LOGGER : get the list of available loggers"
    Circuits.loggers.list_available.each do |logger|
      puts " * #{logger}"
    end
    puts ''

    puts "4.3/ LOGGER : change logger to :perso"
    Circuits.loggers.current = :perso
    puts ""





    # sample Mattermost notification
    puts "5/ set notifier mattermost on dummy url, change with your slack or mattermost server"
    Sc4ry::Notifiers::config name: :mattermost, config: {:url => 'https://mattermost.mycorp.com', :token => "<TOKEN>"}
    puts ""


    # sample loop
    puts "6/ running circuits test, please wait ... (see /tmp/logfile.log for result)"
    puts " check endoint status for different result, you cloud use http://github.com/Ultragreen/MockWS for testing endpoint, on an other tty"
    puts "  $ git clone https://github.com/Ultragreen/MockWS.git"
    puts "  $ cd MockWS"
    puts "  $ rackup"
    begin
      10.times do
        sleep 1
        Circuits.run circuit: :test do
          # for the test choose or build an endpoint you must shutdown
          puts RestClient.get('http://localhost:9292/test2/data')
        end
      end
    rescue Interrupt
      puts 'Interrputed'
    ensure
      Circuits.store.flush
    end

    puts "end"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ultragreen/sc4ry. 

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


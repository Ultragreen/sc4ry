# Sc4ry : Simple CircuitBreacker For RubY

Sc4ry provide the Circuit Breaker Design Pattern for your applications

![Sc4ry logo](assets/images/logo_sc4ry.png) _Simple CircuitBreacker 4 RubY_

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

### sample with Restclient

```ruby

require 'rubygems'
require 'sc4ry'


# defining a circuit, config must be empty or override from default
Sc4ry::Circuits.register({:circuit =>:test, :config => {:notifiers => [:prometheus, :mattermost], :exceptions => [Errno::ECONNREFUSED], :timeout =>  true, :timeout_value => 3, :check_delay => 5 }})

# display the list of known circuit
pp Sc4ry::Circuits.list

# display default config, must be override with a nested hash by calling default_config= method
pp  Sc4ry::Circuits.default_config


# Config an alternate logger 
Sc4ry::Logger.register name: :perso, instance: ::Logger.new('/tmp/logfile.log')
Sc4ry::Logger::current = :perso


# default values, circuit is half open before one of the max count is reached

# {:max_failure_count=>5,                      => maximum failure before opening circuit
#  :timeout_value=>20,                         => timeout value, if :timeout => true
#  :timeout=>false,                            => (de)activate internal timeout
#  :max_timeout_count=>5,                      => maximum timeout try before opening circuit
#  :max_time=>10,                              => maximum time for a circuit run
#  :max_overtime_count=>3,                     => maximum count of overtime before opening circuit
#  :check_delay=>30,                           => delay after opening, before trying again to closed circuit or after an other check
#  :notifiers=>[],                             => active notifier, must be :symbol in [:prometheus, :mattermost]
#  :forward_unknown_exceptions => true,        => (de)activate forwarding of unknown exceptions, just log in DEBUG if false
#  :raise_on_opening => false,                 => (de)activate raise specific Sc4ry exceptions ( CircuitBreaked ) if circuit opening
#  :exceptions=>[StandardError, RuntimeError]} => list of selected Exceptions considered for failure, others are SKIPPED. 

# display configuration for a specific circuit
pp Sc4ry::Circuits.get circuit: :test

# sample Mattermost notification
#Sc4ry::Notifiers::config({:name => :mattermost, :config =>  {:url => 'https://mattermost.mycorp.com', :token => "<TOKEN>"}})

# sample loop
100.times do
  sleep 1
  Sc4ry::Circuits.run circuit: :test do 
   # for the test choose or build an endpoint you must shutdown  
   puts RestClient.get('http://<URL_OF_A_ENDPOINT>')
  end
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sc4ry. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/sc4ry/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).



Gem::Specification.new do |spec|
  spec.name          = "sc4ry"
  spec.version       = `cat VERSION`.chomp
  spec.authors       = ["Romain GEORGES"]
  spec.email         = ["romain.georges@orange.com"]

  spec.summary       = %q{Sc4Ry is Simple Circuitbreaker 4 RubY}
  spec.description   = %q{Sc4ry provide the design pattern Circuit breaker for your application.}
  spec.homepage      = "https://github.com/Ultragreen/sc4ry"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
  
  spec.add_dependency "prometheus-client", "~> 3.0"
  spec.add_dependency "rest-client", "~> 2.1"
  spec.add_dependency "redis", "~> 4.6"

  spec.add_development_dependency "yard", "~> 0.9.27"
  spec.add_development_dependency 'code_statistics', '~> 0.2.13'
  spec.add_development_dependency "yard-rspec", "~> 0.1"
  spec.add_development_dependency 'rubocop', '~> 1.32'
  spec.add_dependency "version", "~> 1.1"
end

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "faastruby/version"

Gem::Specification.new do |spec|
  spec.name          = "faastruby"
  spec.version       = FaaStRuby::VERSION
  spec.authors       = ["Paulo Arruda"]
  spec.email         = ["parrudaj@gmail.com"]
  spec.required_ruby_version = '>= 2.5.0'
  spec.summary       = %q{FaaStRuby CLI - Manage workspaces and functions hosted at faastruby.io.}
  spec.homepage      = "https://faastruby.io"
  spec.license       = "MIT"
  spec.add_runtime_dependency 'rest-client', '~> 2.0'
  spec.add_runtime_dependency 'oj', '~> 3.6'
  spec.add_runtime_dependency 'tty-spinner', '~> 0.8'
  spec.add_runtime_dependency 'tty-table', '~> 0.10'
  spec.add_runtime_dependency 'rubyzip', '~> 1.2'
  spec.add_runtime_dependency 'colorize', '~> 0.8'
  spec.add_runtime_dependency 'sinatra', '~> 2.0'
  spec.add_runtime_dependency 'sinatra-contrib', '~> 2.0'
  spec.add_runtime_dependency 'puma', '~> 3.12'
  spec.add_runtime_dependency 'faastruby-rpc', '~> 0.2.1'
  spec.add_runtime_dependency 'filewatcher', '~> 1.1.1'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "webmock", "~> 3.4"
end

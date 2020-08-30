require_relative 'lib/logtastic/version'

Gem::Specification.new do |spec|
  spec.name          = "logtastic"
  spec.version       = Logtastic::VERSION
  spec.authors       = ["Orhan Toy"]
  spec.email         = ["toyorhan@gmail.com"]

  spec.summary       = "Logtastic"
  spec.description   = "Logtastic"
  spec.homepage      = "https://github.com/orhantoy/logtastic"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/orhantoy/logtastic"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "elasticsearch"
  spec.add_dependency "elasticsearch-xpack"
  spec.add_dependency "concurrent-ruby"

  spec.add_development_dependency "byebug"
end

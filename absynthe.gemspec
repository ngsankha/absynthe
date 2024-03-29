require_relative 'lib/absynthe/version'

Gem::Specification.new do |spec|
  spec.name          = "absynthe"
  spec.version       = Absynthe::VERSION
  spec.authors       = ["Sankha Narayan Guria"]
  spec.email         = ["sankha93@gmail.com"]

  spec.summary       = "lelwut"
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"

  spec.add_dependency "rake"
  spec.add_dependency "minitest"
  spec.add_dependency "sxp"
  spec.add_dependency "parser"
  spec.add_dependency "priority_queue_cxx"
end

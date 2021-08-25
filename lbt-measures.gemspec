
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'lbt-measures'
  spec.version       = "0.0.0"
  spec.authors       = ['Dan Macumber', 'Chris Mackey']
  spec.email         = ['chris@ladybug.tools']

  spec.summary       = 'Collection of measures that ship with Ladybug Tools plugins.'
  spec.description   = 'Measures that ship with Ladybug Tools plugins and are regularly tested for compatibility with them.'
  spec.homepage      = 'https://github.com/ladybug-tools/lbt-measures'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = "~> 2.7.0"

  spec.add_dependency 'openstudio-extension', '0.4.3'
  spec.add_development_dependency "bundler",        "~> 2.1"

end

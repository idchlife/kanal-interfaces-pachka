# frozen_string_literal: true

require_relative "lib/kanal/interfaces/pachka/version"

Gem::Specification.new do |spec|
  spec.name = "kanal-interfaces-pachka"
  spec.version = Kanal::Interfaces::Pachka::VERSION
  spec.authors = ["idchlife"]
  spec.email = ["idchlife@gmail.com"]

  spec.summary = "Kanal Interface to work with Pachka messenger"
  spec.description = "Use this interface with your Kanal to create bot for Pachka messenger"
  spec.homepage = "https://github.com/idchlife/kanal-interfaces-pachka"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.6"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/idchlife/kanal-interfaces-pachka"
  spec.metadata["changelog_uri"] = "https://github.com/idchlife/kanal-interfaces-pachka/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "faraday", "2.7.4"
  spec.add_dependency "faraday-multipart", "1.0.4"
  spec.add_dependency "kanal", "0.5.1"
  spec.add_dependency "mini_mime", "1.1.2"
  spec.add_dependency "webrick", "1.8.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

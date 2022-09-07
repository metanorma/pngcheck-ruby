# frozen_string_literal: true

require_relative "lib/pngcheck/version"

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name = "pngcheck"
  spec.version = PngCheck::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email   = ["open.source@ribose.com"]

  spec.summary  = "Ruby interface to pngcheck."
  spec.homepage = "https://github.com/metanorma/pngcheck-ruby"
  spec.license  = "BSD-2-Clause"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|github|travis|circleci)|appveyor)})  # rubocop:disable Layout/LineLength
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi", "~> 1.0"
  spec.add_runtime_dependency "mini_portile2", "~> 2.7"

  spec.add_development_dependency "libpng-ruby", "~> 0.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.4"

  spec.extensions = ["ext/extconf.rb"]
end

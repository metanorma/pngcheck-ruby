# frozen_string_literal: true

require_relative "lib/pngcheck/version"

Gem::Specification.new do |spec|
  spec.name = "pngcheck"
  spec.version = Pngcheck::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email   = ["open.source@ribose.com"]

  spec.summary  = "Ruby interface to pngcheck."
  spec.homepage = "https://github.com/metanorma/pngcheck-ruby"
  spec.license  = "BSD-2-Clause"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "mini_portile2", "~> 2.0"

  spec.extensions = ["ext/extconf.rb"]
end

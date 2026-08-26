# frozen_string_literal: true

require_relative "lib/libambx/version"

Gem::Specification.new do |spec|
  spec.name = "libambx"
  spec.version = Libambx::VERSION
  spec.summary = "Former Combustd Philips amBX USB driver"
  spec.description = "Former Combustd Philips amBX USB driver for controlling compatible lighting devices."
  spec.authors = [ "Martijn de Boer (combustd@sexybiggetje.nl)", "Gert-Jan de Boer" ]
  spec.email = [ "combustd@sexybiggetje.nl" ]
  spec.homepage = "https://github.com/eirvandelden/ambx"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "source_code_uri" => "https://github.com/eirvandelden/ambx"
  }

  spec.files = Dir.glob([
    "lib/**/*",
    "libcombustd/**/*",
    "AUTHORS",
    "CHANGELOG",
    "LICENSE",
    "README",
    "docs/**/*.md"
  ]).select { File.file?(_1) }

  spec.add_dependency "libusb"
end

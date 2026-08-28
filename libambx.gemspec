require_relative "lib/libambx/version"

Gem::Specification.new do |spec|
  spec.name = "libambx"
  spec.version = Libambx::VERSION
  spec.summary = "Former Combustd Philips amBX USB driver"
  spec.description = "Former Combustd Philips amBX USB driver for controlling compatible lighting devices."
  spec.authors = [ "Martijn de Boer (combustd@sexybiggetje.nl)", "Gert-Jan de Boer" ]
  spec.email = [ "combustd@sexybiggetje.nl" ]
  spec.homepage = "https://github.com/eirvandelden/libamBX"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata = {
    "source_code_uri" => "https://github.com/eirvandelden/libamBX",
    "changelog_uri" => "https://github.com/eirvandelden/libamBX/blob/main/CHANGELOG",
    "bug_tracker_uri" => "https://github.com/eirvandelden/libamBX/issues"
  }

  spec.files = %w[
    AUTHORS
    CHANGELOG
    LICENSE
    README
    lib/libambx.rb
    lib/libambx/version.rb
    lib/libcombustd/libcombustd.rb
    libcombustd/communication/ambx.rb
    libcombustd/communication/device.rb
    libcombustd/data/lights.rb
    libcombustd/data/protocoldefinitions.rb
    libcombustd/libcombustd.rb
  ]

  spec.add_dependency "libusb"
end

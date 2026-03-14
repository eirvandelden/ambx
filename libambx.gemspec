require_relative 'libambx/version'

Gem::Specification.new do |spec|
  spec.name          = 'libambx'
  spec.version       = Ambx::VERSION
  spec.authors       = [
    'Etienne van Delden de la Haije',
    'Martijn de Boer',
    'Gert-Jan de Boer'
  ]
  spec.email         = [ 'combustd@sexybiggetje.nl', 'google@nosco-ict.nl' ]

  spec.summary       = 'Ruby USB driver for Philips amBX devices.'
  spec.description   = 'A Ruby USB driver for controlling Philips amBX lights, fans, and rumble devices.'
  spec.homepage      = 'https://github.com/etiennevandelden/libamBX'
  spec.license       = 'BSD-2-Clause'
  spec.required_ruby_version = '>= 3.0'

  library_files = Dir.glob('libambx/**/*').select { |path| File.file?(path) }
  test_files = Dir.glob('test/**/*').select { |path| File.file?(path) }
  support_files = %w[AUTHORS CHANGELOG Gemfile LICENSE README Rakefile libambx.gemspec]

  spec.files = (library_files + test_files + support_files).uniq.select { |path| File.file?(path) }

  spec.require_paths = [ 'libambx' ]

  spec.add_runtime_dependency 'libusb', '>= 0.7', '< 1.0'
end

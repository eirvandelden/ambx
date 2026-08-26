require "minitest/autorun"
require "open3"
require "rbconfig"

class GemPackageTest < Minitest::Test
  def test_canonical_entry_point_loads_the_driver_and_version
    output, status = Open3.capture2(
      RbConfig.ruby,
      "-Ilib",
      "-e",
      'require "libambx"; puts Ambx; puts Libambx::VERSION'
    )

    assert status.success?, output
    assert_includes output, "Ambx\n"
    assert_equal "0.3.0", output.lines.last.strip
  end

  def test_gemspec_describes_the_libambx_package
    specification = Gem::Specification.load("libambx.gemspec")

    assert_equal "libambx", specification.name
    assert_equal [ "BSD-3-Clause" ], specification.licenses
    assert_equal [ "Martijn de Boer (combustd@sexybiggetje.nl)", "Gert-Jan de Boer" ], specification.authors
    assert_equal Gem::Requirement.new(">= 3.1"), specification.required_ruby_version
    assert_equal [ "libusb" ], specification.runtime_dependencies.map(&:name)
  end
end

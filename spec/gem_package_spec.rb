require "minitest/autorun"
require "open3"
require "rbconfig"
require "rubygems/package"
require "tmpdir"

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
    assert_equal "0.4.0", output.lines.last.strip
  end

  def test_gemspec_describes_the_libambx_package
    specification = Gem::Specification.load("libambx.gemspec")

    assert_equal "libambx", specification.name
    assert_equal [ "BSD-3-Clause" ], specification.licenses
    assert_equal [ "Martijn de Boer (combustd@sexybiggetje.nl)", "Gert-Jan de Boer" ], specification.authors
    assert_equal Gem::Requirement.new(">= 3.4"), specification.required_ruby_version
    assert_equal [ "libusb" ], specification.runtime_dependencies.map(&:name)
    assert_equal "https://github.com/eirvandelden/libamBX", specification.homepage
    assert_equal "https://github.com/eirvandelden/libamBX", specification.metadata["source_code_uri"]
    assert_equal "https://github.com/eirvandelden/libamBX/blob/main/CHANGELOG", specification.metadata["changelog_uri"]
    assert_equal "https://github.com/eirvandelden/libamBX/issues", specification.metadata["bug_tracker_uri"]
  end

  def test_built_gem_contains_driver_and_attribution_without_applications_or_tests
    Dir.mktmpdir do |directory|
      gem_path = File.join(directory, "libambx-0.3.0.gem")
      output, status = Open3.capture2("gem", "build", "--output", gem_path, "libambx.gemspec")

      assert status.success?, output

      contents = Gem::Package.new(gem_path).contents
      %w[
        AUTHORS
        LICENSE
        lib/libambx.rb
        lib/libcombustd/libcombustd.rb
        libcombustd/communication/ambx.rb
        libcombustd/communication/device.rb
      ].each { |path| assert_includes contents, path }

      refute contents.any? { |path| path.start_with?("applications/") }
      refute contents.any? { |path| path.start_with?("spec/") }
      refute contents.any? { |path| path.start_with?("docs/") }
    end
  end
end

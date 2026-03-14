require "tmpdir"
require_relative "../../test_helper"
require_relative "../../../applications/menubar/boot"

class RequireSpy
  attr_reader :paths

  def initialize
    @paths = []
  end

  def require(path)
    @paths << path
    true
  end
end

describe Menubar::Boot do
  it "loads bundled standalone gems before libambx inside a Platypus layout" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "libambx"))
      FileUtils.mkdir_p(File.join(dir, "vendor/bundle/bundler"))
      File.write(File.join(dir, "vendor/bundle/bundler/setup.rb"), "# test")
      spy = RequireSpy.new

      Menubar::Boot.load_dependencies(dir, kernel: spy)

      _(spy.paths).must_equal [
        File.join(dir, "vendor/bundle/bundler/setup.rb"),
        File.join(dir, "libambx/libambx")
      ]
    end
  end

  it "uses the repository config path in development mode" do
    Dir.mktmpdir do |dir|
      _(Menubar::Boot.config_path(dir)).must_equal File.join(dir, "config/colors.yml")
    end
  end
end

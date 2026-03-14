module Menubar
  module Boot
    module_function

    def bundled?(base_dir = __dir__)
      File.exist?(File.join(base_dir, "libambx"))
    end

    def config_path(base_dir = __dir__)
      return File.join(base_dir, "colors.yml") if bundled?(base_dir)

      File.join(base_dir, "config/colors.yml")
    end

    def libambx_path(base_dir = __dir__)
      return File.join(base_dir, "libambx/libambx") if bundled?(base_dir)

      File.expand_path("../../libambx/libambx", base_dir)
    end

    def standalone_setup_path(base_dir = __dir__)
      File.join(base_dir, "vendor/bundle/bundler/setup.rb")
    end

    def load_dependencies(base_dir = __dir__, kernel: Kernel)
      standalone_setup = standalone_setup_path(base_dir)
      kernel.require(standalone_setup) if File.exist?(standalone_setup)
      kernel.require(libambx_path(base_dir))
    end
  end
end

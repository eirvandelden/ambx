# spec/build_app_spec.rb
require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class BuildAppScriptTest < Minitest::Test
  BUILD_SCRIPT = File.expand_path(
    "../applications/menubar/build/build-app.sh", __dir__
  )

  def setup
    # Create a fake Caskroom-like directory with a dummy platypus_clt
    @tmpdir = Dir.mktmpdir
    @resources_dir = File.join(
      @tmpdir, "Caskroom", "platypus", "5.5.0",
      "Platypus.app", "Contents", "Resources"
    )
    FileUtils.mkdir_p(@resources_dir)

    fake_clt = File.join(@resources_dir, "platypus_clt")
    @args_file = File.join(@tmpdir, "platypus_args.txt")
    File.write(fake_clt, "#!/bin/bash\nprintf '%s\n' \"$@\" > \"$PLATYPUS_ARGS_FILE\"\necho 'platypus_clt called'\n")
    FileUtils.chmod(0o755, fake_clt)
    # Deliberately NOT creating InstallCommandLineTool.sh or ScriptExec
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # Helper: run the script with env overrides that point to our fake setup
  # PLATYPUS_CLI_OVERRIDE  — injected path for the CLI binary
  # PLATYPUS_RESOURCES_CHECK — injected path for the ScriptExec resource check
  def run_script(extra_env = {})
    fake_clt_path = File.join(
      @tmpdir, "Caskroom", "platypus", "5.5.0",
      "Platypus.app", "Contents", "Resources", "platypus_clt"
    )
    env = {
      "PLATYPUS_CLI_OVERRIDE"      => fake_clt_path,
      "PLATYPUS_RESOURCES_CHECK"   => File.join(@tmpdir, "nonexistent", "ScriptExec"),
      "PLATYPUS_ARGS_FILE"         => @args_file
    }.merge(extra_env)
    Open3.capture3(env, BUILD_SCRIPT)
  end

  def test_exits_nonzero_when_resources_not_installed
    _out, _err, status = run_script
    refute status.success?,
      "Expected non-zero exit when Platypus resources are missing"
  end

  def test_prints_manual_install_command_instead_of_running_sudo
    out, _err, _status = run_script
    assert_includes out, "sudo",
      "Expected output to include the manual sudo command for the user to run"
  end

  def test_does_not_invoke_sudo_automatically
    # The script must not exec sudo — it should only print it
    # We verify by checking the script source has no bare `sudo` call outside echo/print
    source = File.read(BUILD_SCRIPT)
    # Strip comment lines and echo/print lines
    exec_lines = source.lines.reject do |line|
      stripped = line.strip
      stripped.start_with?("#") ||
        stripped.start_with?("echo") ||
        stripped.start_with?("printf")
    end
    refute exec_lines.any? { |l| l.match?(/\bsudo\b/) },
      "build-app.sh must not execute sudo — found sudo call outside echo/printf"
  end

  def test_bundles_menubar_helpers_into_app
    resources_check = File.join(@tmpdir, "share", "platypus", "ScriptExec")
    FileUtils.mkdir_p(File.dirname(resources_check))
    File.write(resources_check, "")

    _out, _err, status = run_script("PLATYPUS_RESOURCES_CHECK" => resources_check)

    assert status.success?, "Expected fake Platypus CLI invocation to succeed"
    args = File.readlines(@args_file, chomp: true)
    assert_includes args, "../menubar_helpers.rb",
      "Expected build-app.sh to bundle menubar_helpers.rb"
  end

  def test_passes_overwrite_flag_for_repeat_builds
    resources_check = File.join(@tmpdir, "share", "platypus", "ScriptExec")
    FileUtils.mkdir_p(File.dirname(resources_check))
    File.write(resources_check, "")

    _out, _err, status = run_script("PLATYPUS_RESOURCES_CHECK" => resources_check)

    assert status.success?, "Expected fake Platypus CLI invocation to succeed"
    args = File.readlines(@args_file, chomp: true)
    assert_includes args, "-y",
      "Expected build-app.sh to pass Platypus' overwrite flag"
  end
end

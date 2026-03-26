require 'fileutils'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'

class BuildAppScriptTest < Minitest::Test
  BUILD_SCRIPT = File.expand_path(
    '../applications/menubar/build/build-app.sh', __dir__
  )
  HELPER_PATH = '../menubar_helpers.rb'

  def setup
    @tmpdir = Dir.mktmpdir
    @resources_dir = fake_resources_dir
    FileUtils.mkdir_p(@resources_dir)
    @args_log = File.join(@tmpdir, 'platypus-args.log')
    fake_clt = File.join(@resources_dir, 'platypus_clt')
    File.write(fake_clt, <<~SH)
      #!/bin/bash
      printf '%s\n' "$@" > "#{@args_log}"
      echo 'platypus_clt called'
    SH
    FileUtils.chmod(0o755, fake_clt)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def run_script(extra_env = {})
    env = {
      'PLATYPUS_CLI_OVERRIDE' => fake_clt_path,
      'PLATYPUS_RESOURCES_CHECK' => nonexistent_script_exec_path
    }.merge(extra_env)
    Open3.capture3(env, BUILD_SCRIPT)
  end

  def test_exits_nonzero_when_resources_not_installed
    _out, _err, status = run_script
    refute status.success?,
           'Expected non-zero exit when Platypus resources are missing'
  end

  def test_prints_manual_install_command_instead_of_running_sudo
    out, _err, _status = run_script
    assert_includes out, 'sudo',
                    'Expected output to include the manual sudo command for the user to run'
  end

  def test_does_not_invoke_sudo_automatically
    source = File.read(BUILD_SCRIPT)
    exec_lines = source.lines.reject do |line|
      stripped = line.strip
      stripped.start_with?('#') ||
        stripped.start_with?('echo') ||
        stripped.start_with?('printf')
    end
    refute exec_lines.any? { |l| l.match?(/\bsudo\b/) },
           'build-app.sh must not execute sudo — found sudo call outside echo/printf'
  end

  def test_bundles_menubar_helper_file
    FileUtils.touch(script_exec_path)
    _out, _err, status = run_script(
      'PLATYPUS_RESOURCES_CHECK' => script_exec_path
    )

    assert status.success?, 'Expected build-app.sh to invoke Platypus successfully'
    assert_includes File.read(@args_log), HELPER_PATH,
                    'Expected build-app.sh to bundle menubar_helpers.rb in the app'
  end

  private

  def fake_resources_dir
    File.join(@tmpdir, 'Caskroom', 'platypus', '5.5.0', 'Platypus.app', 'Contents', 'Resources')
  end

  def fake_clt_path
    File.join(fake_resources_dir, 'platypus_clt')
  end

  def script_exec_path
    File.join(@tmpdir, 'ScriptExec')
  end

  def nonexistent_script_exec_path
    File.join(@tmpdir, 'nonexistent', 'ScriptExec')
  end
end

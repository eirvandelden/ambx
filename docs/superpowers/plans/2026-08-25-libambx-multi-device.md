# libambx multi-device implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers-ruby:subagent-driven-development` (recommended) or `superpowers-ruby:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the existing Combustd amBX USB driver as the `libambx` gem and expose independent, stable-identity USB devices so `ambx2mqtt` can control every connected set without one unplugged set disrupting the others.

**Architecture:** Keep the existing low-level command protocol, but make `Ambx::Device` own exactly one libusb descriptor and handle. `Ambx.devices` discovers unopened devices; explicit device methods handle open/write/close and isolate expected disconnects. The historical broadcast API remains as a deprecated compatibility layer. Package this API under `lib/libambx.rb` while retaining a compatibility require path for applications that still load `libcombustd` directly.

**Tech Stack:** Ruby 3.1+, `libusb` 0.7+, Minitest, RubyGems, Bundler, Rake.

---

## Structure after this change

```text
lib/
  libambx.rb                         # canonical gem entry point
  libambx/version.rb                 # Libambx::VERSION
  libcombustd/libcombustd.rb          # legacy entry point forwarding to libambx
libcombustd/
  communication/
    ambx.rb                          # discovery and deprecated broadcast facade
    device.rb                        # one physical USB device and its identity
  data/                              # retained protocol commands and light constants
libambx.gemspec                      # RubyGems metadata and packaged-file allowlist
Rakefile                             # one command for the complete test suite
spec/
  ambx_spec.rb                       # per-device and legacy compatibility tests
  gem_package_spec.rb                # canonical require and gemspec assertions
docs/releasing.md                    # reproducible release procedure
```

Delete the obsolete macOS menubar application and its dedicated tests:

```text
applications/menubar/
spec/build_app_spec.rb
spec/menubar/
```

Do not delete unrelated root-level untracked files, including `screenshot.png`.

## Task 1: Establish the canonical gem entry point and package metadata

**Files:**

- Create: `lib/libambx.rb`
- Create: `lib/libambx/version.rb`
- Create: `lib/libcombustd/libcombustd.rb`
- Create: `libambx.gemspec`
- Modify: `Gemfile`
- Create: `Rakefile`
- Create: `spec/gem_package_spec.rb`

- [ ] **Step 1: Write the failing package and load-path tests.**

  Verify that `require "libambx"` exposes `Ambx`, `Libambx::VERSION` is `"0.3.0"`, and loading the gemspec reports `name == "libambx"`, the BSD-3-Clause license, the original Combustd authors, Ruby `>= 3.1`, and runtime dependency `libusb`.

  Use a temporary subprocess for the require test so a previous test cannot mask a bad load path:

  ```ruby
  output = IO.popen([RbConfig.ruby, "-Ilib", "-e", 'require "libambx"; print Libambx::VERSION'], &:read)
  assert_equal "0.3.0", output
  ```

- [ ] **Step 2: Run the new test and confirm it fails for the missing canonical entry point.**

  Run: `bundle exec ruby spec/gem_package_spec.rb`

  Expected: a load error for `libambx` or a missing-file failure, before production files are added.

- [ ] **Step 3: Add the smallest working gem skeleton.**

  `lib/libambx.rb` must load the existing driver from the package root. `lib/libcombustd/libcombustd.rb` must warn with a one-release migration message and then load `libambx`; do not create a second copy of driver code.

  Define only the version namespace in `lib/libambx/version.rb`:

  ```ruby
  module Libambx
    VERSION = "0.3.0"
  end
  ```

  Make `libambx.gemspec` use an explicit file allowlist limited to `lib/**/*`, `libcombustd/**/*`, top-level attribution/readme/changelog files, and `docs/**/*.md`; exclude `applications/` and test fixtures. Its summary and description must identify this as the former Combustd Philips amBX USB driver, retain Martijn de Boer (`combustd@sexybiggetje.nl`) and Gert-Jan de Boer in `authors`, point to `https://github.com/eirvandelden/ambx`, and declare the unchanged BSD 3-Clause license.

  Replace the Gemfile's standalone runtime dependency with `gemspec`, keep development tools, and add `rake`. Add a `Rake::TestTask` that runs `spec/**/*_spec.rb` so the suite has one release-ready command.

- [ ] **Step 4: Make the package tests pass.**

  Run: `bundle install && bundle exec ruby spec/gem_package_spec.rb && bundle exec rake test`

  Expected: package/load-path tests and the existing driver tests pass.

- [ ] **Step 5: Commit the package foundation.**

  ```bash
  git add Gemfile Gemfile.lock Rakefile lib libambx.gemspec spec/gem_package_spec.rb
  git commit -m "feat(libambx): Add canonical gem package"
  ```

## Task 2: Model one physical amBX USB set

**Files:**

- Create: `libcombustd/communication/device.rb`
- Modify: `libcombustd/communication/ambx.rb`
- Modify: `libcombustd/libcombustd.rb`
- Modify: `spec/ambx_spec.rb`

- [ ] **Step 1: Extend the libusb fakes and write device discovery tests.**

  Extend the existing fake device to expose `serial_number`, `port_path`, `bus_number`, and `device_address`. Test `Ambx.devices` returns one unopened `Ambx::Device` for every descriptor matching the Philips vendor/product IDs and filters non-amBX devices.

  Cover the identity contract:

  - a non-empty USB serial yields `"serial:<serial>"`;
  - no serial yields `"port:<dot-separated-port-path>"`;
  - if no port path exists, fall back to `"usb:<bus>-<address>"`;
  - `serial_number` and `port_path` are exposed for friendly-name configuration by a caller.

- [ ] **Step 2: Run the focused tests and confirm discovery fails before implementation.**

  Run: `bundle exec ruby spec/ambx_spec.rb`

  Expected: failures because `Ambx.devices` and `Ambx::Device` do not yet exist.

- [ ] **Step 3: Implement `Ambx::Device` with no implicit I/O.**

  Make the device retain its descriptor and provide exactly these public methods:

  ```ruby
  def identity; end
  def serial_number; end
  def port_path; end
  def open; end
  def connected?; end
  def write(bytes); end
  def close(clear_lights: false); end
  ```

  `open` opens and claims only its own interface, is idempotent, returns `self`, and raises unexpected libusb errors. `connected?` is true only with an opened handle. `close` releases/clears only that handle and is idempotent. With `clear_lights: true`, send the existing black/clear command before release; the normal default must not change lights.

  Do not poll or invent hardware state readback. `ambx2mqtt` will persist requested state separately.

- [ ] **Step 4: Refactor `Ambx` discovery to build devices.**

  `Ambx.devices` must enumerate the existing supported VID/PID pair each call and return fresh unopened device objects. Keep endpoint/interface constants and protocol helpers in their current ownership; do not change command bytes or light addresses.

- [ ] **Step 5: Run the focused test suite.**

  Run: `bundle exec ruby spec/ambx_spec.rb`

  Expected: discovery, identity, unopened state, open, and close behavior pass.

- [ ] **Step 6: Commit the device model.**

  ```bash
  git add libcombustd/communication libcombustd/libcombustd.rb spec/ambx_spec.rb
  git commit -m "feat(libambx): Discover physical amBX devices"
  ```

## Task 3: Isolate expected USB disconnects per device

**Files:**

- Modify: `libcombustd/communication/device.rb`
- Modify: `spec/ambx_spec.rb`

- [ ] **Step 1: Write the disconnect and error-propagation tests.**

  Use two fake handles. Make the first handle's interrupt transfer raise `Errno::ENXIO` and assert that its `Device#write` returns `false`, closes only that first handle, and makes `connected?` false. Assert the second device stays connected and can still write.

  Add a separate test that a non-`ENXIO` exception (for example `LIBUSB::ERROR_ACCESS`) is raised to the caller and does not get converted into `false`.

- [ ] **Step 2: Run the focused failures.**

  Run: `bundle exec ruby spec/ambx_spec.rb`

  Expected: the ENXIO-isolation and unexpected-error tests fail before the write path changes.

- [ ] **Step 3: Implement the narrow disconnect boundary.**

  In `Device#write`, return `false` only for `Errno::ENXIO`; release and discard only that device's handle without requesting a light clear. Re-raise every other error. A successful transfer returns `true` (or the transfer's positive success result, documented and tested consistently).

  Keep cleanup safe if the physical device vanished during release: rescue only the expected disconnect from cleanup, and never call global `Ambx.close` from a device method.

- [ ] **Step 4: Verify the full unit suite.**

  Run: `bundle exec rake test`

  Expected: all tests pass, including continued control of the unaffected fake device.

- [ ] **Step 5: Commit disconnect isolation.**

  ```bash
  git add libcombustd/communication/device.rb spec/ambx_spec.rb
  git commit -m "fix(libambx): Isolate USB disconnects per device"
  ```

## Task 4: Preserve and deprecate the broadcast API deliberately

**Files:**

- Modify: `libcombustd/communication/ambx.rb`
- Modify: `spec/ambx_spec.rb`
- Modify: `README`
- Modify: `CHANGELOG`

- [ ] **Step 1: Add compatibility tests before changing the facade.**

  Test that `Ambx.connect` retains its legacy role by discovering/opening all current devices, `Ambx.write_all(bytes)` writes in discovery order, and `Ambx.write(bytes)` emits a deprecation warning then delegates to `write_all`.

  Test the legacy broadcast path stops on the first `false` result and closes its remaining legacy devices, matching the old all-or-nothing disconnect behavior. This behavior is intentionally separate from direct `Device#write` isolation.

- [ ] **Step 2: Run compatibility tests and confirm the missing API failure.**

  Run: `bundle exec ruby spec/ambx_spec.rb`

  Expected: failures for `write_all` and deprecation behavior before implementation.

- [ ] **Step 3: Implement the facade on top of `Ambx.devices`.**

  Keep `Ambx.connect`, `Ambx.open`, and `Ambx.close` callable for current applications, but implement their cached collection with `Ambx::Device` objects. Add explicit `write_all`; make `write` warn once per process with the exact migration target `Ambx.write_all` and delegate. Ensure `Ambx.close` calls `device.close(clear_lights: true)` only where the historical behavior previously cleared all lights.

  Document the preferred multi-device usage in the README:

  ```ruby
  Ambx.devices.each do |device|
    device.open
    device.write(Lights.light_color(Lights::LEFT, 255, 0, 0))
  ensure
    device&.close
  end
  ```

- [ ] **Step 4: Record the user-visible change.**

  Add a `0.3.0` changelog entry for the gem rename/package, `Ambx.devices`, stable identity, per-device ENXIO handling, and deprecated broadcast alias. Keep the historical entries intact.

- [ ] **Step 5: Run regression tests.**

  Run: `bundle exec rake test`

  Expected: all device and legacy tests pass.

- [ ] **Step 6: Commit backwards compatibility.**

  ```bash
  git add README CHANGELOG libcombustd/communication/ambx.rb spec/ambx_spec.rb
  git commit -m "feat(libambx): Keep legacy broadcast control compatible"
  ```

## Task 5: Remove the unsupported menubar application

**Files:**

- Delete: `applications/menubar/`
- Delete: `spec/build_app_spec.rb`
- Delete: `spec/menubar/`
- Modify: `.gitignore`
- Modify: `README`
- Modify: `CHANGELOG`

- [ ] **Step 1: Remove only the approved obsolete targets.**

  Delete the full menubar application directory and its dedicated tests. Remove the obsolete `applications/menubar/build/*.app/` ignore rule. Leave `applications/image2ambx/`, `applications/onefile/`, and all unrelated untracked files untouched.

- [ ] **Step 2: Replace the old user-facing application guidance.**

  Update the README to describe `libambx` as a driver gem and point users to the forthcoming separate `ambx2mqtt` project for Home Assistant integration. Do not claim that `ambx2mqtt` is published or runnable yet.

- [ ] **Step 3: Run the suite without the deleted specs.**

  Run: `bundle exec rake test && git diff --check`

  Expected: the remaining suite passes and the diff has no whitespace errors.

- [ ] **Step 4: Commit removal independently.**

  ```bash
  git add -u applications/menubar spec/build_app_spec.rb spec/menubar .gitignore README CHANGELOG
  git commit -m "chore: Remove unsupported menubar application"
  ```

## Task 6: Complete release documentation and validate the built artifact

**Files:**

- Create: `docs/releasing.md`
- Modify: `README`
- Modify: `INSTALL`
- Modify: `AUTHORS`
- Modify: `CHANGELOG`
- Modify: `libambx.gemspec`
- Modify: `spec/gem_package_spec.rb`

- [ ] **Step 1: Add failing artifact-content assertions.**

  Build the gem into `pkg/` in test setup or a temporary directory, inspect it with `Gem::Package`, and assert it contains the canonical entry point, compatibility loader, protocol implementation, `LICENSE`, and `AUTHORS`, but not `applications/menubar` or `spec/`.

- [ ] **Step 2: Run the package test and observe the initial artifact failure.**

  Run: `bundle exec ruby spec/gem_package_spec.rb`

  Expected: a specific missing/extra-file assertion until the gemspec allowlist is corrected.

- [ ] **Step 3: Make attribution and release instructions publish-ready.**

  Keep the current copyright and BSD 3-Clause text byte-for-byte in `LICENSE`. In `AUTHORS`, preserve the original Combustd authors and add any current maintainer only as an additional role; never replace authorship. In README and INSTALL, show RubyGems installation (`gem install libambx`) plus a development checkout flow (`bundle install`, `bundle exec rake test`).

  `docs/releasing.md` must include: updating `Libambx::VERSION` and CHANGELOG, checking `git status`, running `bundle exec rake test`, running `gem build libambx.gemspec`, inspecting `gem contents libambx-<version>.gem`, installing that exact artifact in a clean temporary gem home and requiring `libambx`, re-checking `gem search --remote --exact libambx` immediately before publication, and `gem push libambx-<version>.gem`. Explain that `gem push` requires the maintainer's RubyGems credentials and must not be run by automated tests.

- [ ] **Step 4: Make package tests pass and run the release checks.**

  Run:

  ```bash
  bundle exec rake test
  gem build libambx.gemspec
  gem contents libambx-0.3.0.gem
  git diff --check
  ```

  Expected: passing tests, successful `.gem` build, package contents match the assertions, and no diff errors. Do not run `gem push` in this implementation task.

- [ ] **Step 5: Commit release readiness.**

  ```bash
  git add AUTHORS CHANGELOG INSTALL README docs/releasing.md libambx.gemspec spec/gem_package_spec.rb
  git commit -m "docs(libambx): Document release process and attribution"
  ```

## Task 7: Final review and real-hardware acceptance

**Files:**

- Review: all files changed by Tasks 1-6

- [ ] **Step 1: Inspect the aggregate diff and commit history.**

  Run:

  ```bash
  git status --short
  git log --oneline main..HEAD
  git diff --check main...HEAD
  git diff main...HEAD
  ```

  Expected: only intentional libambx, package, documentation, and approved menubar-removal changes; no accidental root untracked-file deletion.

- [ ] **Step 2: Run static and dependency checks if the existing project supports them.**

  Run: `bundle exec rubocop && bundle exec brakeman && bundle exec bundler-audit check --update`

  Expected: report any pre-existing or environment-caused failures separately from regressions; do not silently waive new offenses.

- [ ] **Step 3: Perform a real-hardware acceptance check when an amBX set is connected.**

  In a one-off Ruby process, enumerate `Ambx.devices`, print each identity/serial/port path, open one device at a time, set its five known lights (left, right, wallwasher left/centre/right) to distinct colours, then close it without clearing. Unplug one set during a controlled write and verify its write returns `false` while a second set remains controllable. Do not claim this is completed when no hardware is attached.

- [ ] **Step 4: Record acceptance evidence and prepare review.**

  Add any hardware outcome to the release notes or PR description, distinguishing automated verification from an unavailable physical-device check. Do not publish to RubyGems without an explicit release instruction from the maintainer.

## Deferred to the separate `ambx2mqtt` repository

This plan deliberately does not implement MQTT, Home Assistant discovery, persistence, launchd/systemd service files, friendly-name configuration, 48-hour retained-entity handling, fan control, rumblers, or rotary wheels. The separate daemon will consume `Ambx.devices` and `Ambx::Device#identity` from this gem.

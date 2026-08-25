# `libambx` multi-device design

## Purpose

Make this repository publishable as the `libambx` Ruby gem and add independent control of every connected Philips amBX USB controller. The gem remains a USB-driver boundary; the separate `ambx2mqtt` application will own MQTT, Home Assistant discovery, persisted requested state, and daemon lifecycle.

## Scope

This release adds per-device discovery, identity, connection lifecycle, and write routing for lights. It removes the broken, unsupported macOS menubar application and its dedicated build/helper tests. It preserves a deliberately named broadcast compatibility path, prepares fan addressing for a later consumer release, and supplies complete RubyGems publication metadata and verification. It does not implement MQTT, Home Assistant, hardware-state readback, automated gem publishing, or fan/rumbler/rotary-wheel entities.

## Architecture

`Ambx` remains the public namespace, but device state moves out of its process-wide handle array into `Ambx::Device` instances. `Ambx.devices` performs a fresh USB discovery and returns one unopened device object for every USB descriptor matching Philips vendor `0x0471` and product `0x083F`.

Each `Ambx::Device` owns one USB descriptor and, once opened, one claimed USB handle. It exposes immutable discovery metadata and the operations `open`, `connected?`, `write(bytes)`, and `close(clear_lights: false)`. A caller such as `ambx2mqtt` retains its device instance while it is available, discards it after a disconnection, and discovers again on the next scan.

### Identity

`Device#identity` is stable across normal reconnects in this order:

1. `serial:<serial_number>` when the descriptor reports a non-empty serial number.
2. `port:<port_path>` when no serial is available.

The port-path fallback is stable only while the controller remains connected to the same physical USB topology. The gem exposes both raw values so callers can report the fallback and map a friendly name. A matching device with neither usable serial nor port path is returned with no persistent identity; it remains controllable for the current connection but callers must not persist or use it as a Home Assistant identifier.

### Command and disconnect contract

`Device#write(bytes)` sends the byte sequence only to its own interrupt-out endpoint. It returns `true` after a completed transfer. If libusb reports `Errno::ENXIO`, the method closes and clears only that device's handle, returns `false`, and leaves every other `Ambx::Device` usable. This is the expected unplug/replug signal consumed by `ambx2mqtt`.

Unexpected USB errors and invalid caller input are not converted to `false`; they remain exceptions for the caller to log and diagnose. `close(clear_lights: true)` writes black only to that device's five light addresses before releasing its handle. `open` is idempotent for an already connected device and returns `false` only when the device cannot be opened or its USB interface cannot be claimed.

### Broadcast compatibility

`Ambx.write_all(bytes)` is the explicit legacy broadcast operation. It works only on devices opened through the legacy `Ambx.connect`/`Ambx.open` flow and retains the existing stop-on-first-disconnect behavior for that compatibility surface.

`Ambx.write(bytes)` remains a deprecated alias of `write_all(bytes)` for one compatibility release. New callers must use `Ambx.devices` and `Ambx::Device`; repository applications will migrate to the supported `require "libambx"` entry point without requiring a behavior change in this release.

## Gem packaging and attribution

The gem is named `libambx`, version `0.3.0`, and is sourced from `https://github.com/eirvandelden/ambx`. The gemspec declares:

- BSD-3-Clause licensing and the existing `libusb` runtime dependency.
- Ruby `>= 3.1`, matching a maintained modern Ruby baseline while remaining compatible with the `libusb` dependency.
- Homepage, source-code, changelog, and bug-tracker metadata.
- An explicit allowlist of shipped library, license, authorship, README, changelog, and documentation files.

`lib/libambx.rb` becomes the canonical load path for `require "libambx"`; a version file supplies the gem version. Compatibility loaders preserve the historical `libcombustd` source path during the transition, while packaged consumers use only the canonical require path.

Combustd is preserved as the original project name and historical origin. The README identifies `libambx` as a maintained continuation of Combustd; `AUTHORS` continues to credit Martijn de Boer (`combustd@sexybiggetje.nl`) and Gert-Jan de Boer; and the existing BSD 3-Clause `LICENSE` and copyright notices remain unchanged. New metadata must not imply endorsement by the original authors.

## Tests and verification

Unit tests use fake USB descriptors and handles to verify:

- Discovery filters the correct vendor/product and returns one device object per matching descriptor.
- Serial identity takes precedence over port path, and a missing serial uses port path.
- A command reaches only its target device handle.
- `ENXIO` affects only the target device, closing its handle while another device continues to accept writes.
- `open` and `close` are idempotent per device.
- Legacy `connect`, `open`, `write_all`, and deprecated `write` retain their documented broadcast behavior.

The release gate runs the test suite and RuboCop, builds `libambx-0.3.0.gem`, inspects its files and metadata, installs that exact artifact into a clean temporary gem home, and verifies `require "libambx"`. A real-device acceptance pass then verifies serial-number presence and stability, port-path fallback, independent writes to multiple attached sets, and unplug/replug recovery. The RubyGems name is checked again immediately before a manually authorized `gem push`; no token, credential, or automated publishing workflow is added.

## Implementation sequence

1. Establish the gem layout, version, gemspec, canonical entry point, and compatibility loader without changing existing runtime behavior.
2. Add `Ambx::Device`, identity discovery, per-device handle lifecycle, and unit tests.
3. Move broadcast behavior behind `write_all`, retain `write` as a documented deprecated alias, and update repository applications to use the canonical require path.
4. Remove `applications/menubar/`, `spec/build_app_spec.rb`, and `spec/menubar/`; do not remove unrelated root-level untracked files.
5. Update README, AUTHORS attribution, changelog, installation instructions, and release runbook.
6. Run the release gate and real-device acceptance tests. Publish only after explicit separate authorization.

## Decisions

- "Make 2 plans, one for the changes needed in libambx and another to develop the new daemon" — the driver gem and Home Assistant daemon stay as separate projects.
- "ambx2mqtt should first be developer-oriented" — this gem supplies a dependable library dependency; it does not own daemon packaging.
- "If [USB serials] do [exist], we can make configurable friendly names" — serial is the preferred exposed identity, with USB port path as fallback.
- `Ambx::Device` is the new per-controller API, while `Ambx.write_all` is an explicit compatibility API and `Ambx.write` is temporarily deprecated.
- Expected unplug events return `false` from only the affected `Device#write`; unexpected errors still raise.
- The gem is publishable as `libambx` from `eirvandelden/ambx`, with `0.3.0` as the first RubyGems release.
- Preserve Combustd's name, the authors Martijn de Boer and Gert-Jan de Boer, and the existing BSD 3-Clause license and notices.
- Remove the broken menubar application completely rather than repair it, including its application files and dedicated tests; preserve unrelated files outside that owned surface.

# Releasing libambx

This runbook prepares a RubyGems release without publishing it accidentally.
Only a maintainer with the intended RubyGems credentials may run the final
`gem push` command.

## Prepare the release

1. Update `Libambx::VERSION` in `lib/libambx/version.rb` and add a matching
   entry to `CHANGELOG`.
2. Confirm the working tree contains only intended changes.

   ```sh
   git status --short
   ```

3. Run the complete local suite.

   ```sh
   bundle exec rake test
   ```

4. Build the artifact and inspect its manifest. Do not publish at this step.

   ```sh
   gem build libambx.gemspec
   ruby -rrubygems/package -e 'puts Gem::Package.new(ARGV.fetch(0)).contents' libambx-<version>.gem
   ```

   Confirm the archive contains the canonical `lib/libambx.rb`, the legacy
   compatibility loader, `libcombustd/`, `AUTHORS`, and `LICENSE`; it must not
   contain applications or test files.

5. Install exactly that artifact in a clean temporary gem home and load it.

   ```sh
   RELEASE_GEM_HOME="$(mktemp -d)"
   GEM_HOME="$RELEASE_GEM_HOME" GEM_PATH="$RELEASE_GEM_HOME" gem install --local --no-document libambx-<version>.gem
   GEM_HOME="$RELEASE_GEM_HOME" GEM_PATH="$RELEASE_GEM_HOME" ruby -e 'require "libambx"; abort Libambx::VERSION unless Libambx::VERSION == "<version>"'
   ```

6. Immediately before publishing, ensure the intended RubyGems name is still
   available (or that you are deliberately publishing a new version of the
   existing gem).

   ```sh
   gem search --remote --exact libambx
   ```

## Publish

Authenticate to RubyGems using the maintainer's normal credential mechanism,
then explicitly publish the inspected artifact:

```sh
gem push libambx-<version>.gem
```

Do not run `gem push` from automated tests or an unattended script. Record the
published version and tag/commit in the release announcement.

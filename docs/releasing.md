# Releasing libambx

This gem is not published on RubyGems. Callers depend on it straight from GitHub — `ambx2mqtt`
asks for `gem "libambx", github: "eirvandelden/libamBX"` — and Bundler pins the revision it
resolved in the caller's own lockfile. A release is therefore a merge to `main`; there is nothing
to push and no tag to cut.

The version and the changelog are the whole announcement: they are how someone pinned to an older
revision learns what changed and why to move.

## Prepare the release

1. Update `Libambx::VERSION` in `lib/libambx/version.rb`, add a matching entry to `CHANGELOG`, and
   bump the version the packaging test expects in `spec/gem_package_spec.rb`.

2. Refresh this repository's own lockfile. The gem is a path gem in its own `Gemfile`, so a version
   bump leaves `Gemfile.lock` naming the old one, and the frozen install in CI refuses to carry on.

   ```sh
   bundle install
   ```

   Confirm the diff shows the new version, and beware a `bundle` binstub from another checkout on
   your `PATH`: it resolves that checkout's `Gemfile` instead of this one and does nothing here.

3. Confirm the working tree contains only intended changes.

   ```sh
   git status --short
   ```

4. Run the complete local suite.

   ```sh
   bundle exec rake test
   bundle exec rubocop
   ```

5. Prove the canonical entry point loads and reports the new version, the way a caller gets it.

   ```sh
   ruby -Ilib -e 'require "libambx"; puts Libambx::VERSION'
   ```

6. Confirm the gemspec still hands out everything a caller needs and nothing it should not.

   ```sh
   ruby -e 'puts Gem::Specification.load("libambx.gemspec").files'
   ```

   Expect the canonical `lib/libambx.rb`, the legacy compatibility loader, `libcombustd/`,
   `AUTHORS`, `CHANGELOG`, `LICENSE`, and `README`; it must not list applications or test files.

## Publish

Merge to `main`. Callers pick the release up on their next `bundle update libambx`, which rewrites
the revision in their lockfile.

Verify against a caller before calling it done:

```sh
cd ~/Developer/ambx2mqtt
bundle update libambx
git diff Gemfile.lock
bundle exec rake test
```

The lockfile diff should name the merge commit and the new version.

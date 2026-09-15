# Fix helper loading for 0.2.0

Status: implemented

## Problem

The published 0.1.0 engine resolves `Engine.helpers` when Action Controller loads.
If that happens before Rails sets up the main autoloader, boot raises
`NameError: uninitialized constant ActionVersionPreview::SwitcherHelper`.
This blocked PostMoney's staging asset-precompile build.

The checkout already removes that eager enumeration, but its replacement refers
to an autoloaded helper from an Action View hook. If Action View has already
loaded, registering the hook executes it immediately, still before main
autoloading is necessarily ready. The ordinary dummy-app tests do not exercise
these early loading sequences.

## Implementation

1. Add fresh-process regression tests with a minimal host. Exercise early Action
   Controller and Action View loading, ordinary lazy loading, eager loading, and
   reloading. Render the actual switcher with `include_all_helpers = false`.
2. Move the stateless switcher helper to `lib/action_version_preview`, require it
   explicitly from the engine, and retain the Action View inclusion hook. This
   gives the hook a defined, non-reloadable module regardless of when it runs and
   avoids retaining a stale autoloaded helper after development reloads.
3. Build and install the candidate gem in a temporary directory. Run an isolated
   production host's asset-precompile task and render the helper using that
   installed payload, asserting the implementation came from the package.
4. Update the changelog and architecture notes, and record completion in the
   0.2.0 research backlog. Keep the version bump and publication for the release.

## Validation and acceptance

- Demonstrate that early Action View loading fails before the implementation.
- All boot sequences complete and render switcher links from the engine partial.
- A reloadable host can render before and after a Rails reload.
- The installed package succeeds with `RAILS_ENV=production` and
  `SECRET_KEY_BASE_DUMMY=1`, without a database or external service.
- Run the full Minitest suite, CI/eager-loading mode, RuboCop, and Zeitwerk check.
- No changes to PostMoney, dependency resolution, unrelated review findings,
  version number, or published releases.

## Results

- Moved `SwitcherHelper` into `lib` and explicitly required it from the engine.
- Added four fresh-process tests. Before the fix, early loading, reload-host boot,
  and installed-package boot failed with `SwitcherHelper` NameErrors; lazy boot
  passed. All four now pass.
- The package test builds and installs into a temporary directory, blocks fallback
  to the checkout library, verifies source paths, compiles a real CSS asset via
  Propshaft in production mode, and renders the switcher from the engine partial.
- Normal and `CI=true` suites: 18 tests, 45 assertions, no failures or errors.
- RuboCop: 42 files, no offenses. `app:zeitwerk:check`: passes.
- Updated the changelog, architecture notes, and research implementation status.
- Validation used Ruby 4.0.5 and Rails 8.1.3.1. PostMoney's Docker build and the full
  supported-version matrix were not run. Version bump and publication remain
  part of the 0.2.0 release process.

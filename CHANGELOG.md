# Changelog

All notable changes to this project are documented here.

## [0.2.0] - 2026-09-15

### Fixed

- Fixed `ActionVersionPreview::SwitcherHelper` load-order errors during Rails boot
  and asset precompilation, including early controller/view loading.
- Kept switcher links on the current path, preserving mounted prefixes, nested
  query filters, and configured preview parameter names. Query keys are no longer
  interpreted as Rails routing options.
- Excluded POST body fields from switcher URLs.

### Added

- Fresh-process regression tests for early/lazy framework loading, development
  reloading, and production asset precompilation using a built and installed gem.
- Integration tests for switcher URL safety, mounted paths, custom parameters,
  nested filters, and POST-body exclusion.
- Comprehensive public usage documentation and upgrade instructions, included
  with the gem alongside this changelog.

### Changed

- Explicitly load the stateless switcher helper from `lib` so its availability does
  not depend on Rails autoloading or reloading.
- Updated development dependency resolution and GitHub Actions versions.
- Clarified supported integration behavior and current discovery limitations.

No migrations or required configuration changes. Declared Ruby/Rails requirements,
preview access defaults, and Default-link behavior are unchanged. Full details are
in the [0.2.0 release notes](docs/releases/0.2.0.md).

## [0.1.0] - 2025-12-17

### Added

- Initial release.
- Side-by-side UI previews in separate tabs using Rails view variants.
- Automatic integration with `ActionController::Base`.
- Optional variant switcher and configurable preview parameter/access check.
- Declared support for Rails 7.0 through 8.x.

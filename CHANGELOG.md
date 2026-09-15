# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - Unreleased

### Fixed

- Load the switcher helper explicitly before registering Rails load hooks, preventing `ActionVersionPreview::SwitcherHelper` errors when controllers or views load early during boot and asset precompilation.

### Added

- Fresh-process regression tests for early and lazy framework loading, development reloading, and production asset precompilation using a built and installed gem.

## [0.1.0] - 2025-12-17

### Added
- Initial release
- Preview multiple view variants side-by-side using Rails' built-in view variants
- Zero-config Rails engine integration
- Support for Rails 7.0 through 8.x

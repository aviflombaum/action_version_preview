# Build switcher URLs from the current path and query data

Status: implemented

## Problem

The switcher passes `request.params` into Rails `url_for`. Query keys such as
`host`, `protocol`, and `script_name` become URL-generation options and can send
users to another site or path. The same hash also includes request-body fields,
which should not be copied into navigation links.

## Implementation

1. Add a small URL helper shared by Default and variant links. Use the current
   request path, including its mounted prefix, and encode only
   `request.query_parameters`. Replace or remove the configured preview key as a
   string. Never interpret query keys as routing options.
2. Keep Default's current behavior of removing the preview parameter. Default/exit
   UX changes belong to a separate backlog item.
3. Render the switcher in the dummy layout and add three integration tests:
   hostile URL-option keys with nested filters; configured parameter names with
   a mounted prefix; and a POST response whose body must not appear in links.
   Check actual rendered link destinations and parsed query data, not query order.
4. Document the fix in the changelog and mark research item 1 implemented.

## Validation

Demonstrate the URL regressions before changing the implementation, then run the
full suite and RuboCop. Existing packaged-gem boot/precompile coverage runs as part
of the suite. No new dependencies or browser test infrastructure are needed.

## Results

- Added the private `variant_preview_path` helper and used it for both link types.
  It keeps `request.path`, copies query parameters, and changes only the preview
  key; Default still removes the key.
- Added three integration tests using the actual switcher in the dummy layout.
  The URL-option and POST-body tests failed before the fix and now pass. The
  mounted-prefix case checks both string and symbol configuration values.
- `bin/rails test`: 21 tests, 101 assertions, no failures or errors, including the
  existing installed-package boot and production asset-precompile test.
- `bin/rubocop`: 43 files, no offenses. `git diff --check`: passes.
- Updated README, changelog, and the research backlog. No dependencies changed.
- The preceding load-order work was committed as `6721a9d`; this implementation
  is on `release-0-2-0/safe-switcher-urls`.

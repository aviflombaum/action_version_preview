# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ActionVersionPreview is a Rails engine that enables side-by-side preview of multiple UI versions using Rails' native view variants. It provides zero-config integration via a concern auto-included in all controllers.

## Commands

```bash
# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/integration/variant_preview_test.rb

# Run a single test by line number
bin/rails test test/integration/variant_preview_test.rb:10

# Build the gem
bundle exec rake build

# Release to RubyGems (tags, pushes, publishes)
bundle exec rake release

# Start dummy app for manual testing
bin/rails server
```

## Architecture

### Core Components

- **`lib/action_version_preview.rb`** - Main module with configuration (`param_name`, `access_check`)
- **`lib/action_version_preview/engine.rb`** - Rails engine that auto-includes ControllerMethods in ActionController::Base
- **`lib/action_version_preview/controller_methods.rb`** - The concern with `before_action :set_view_variant` and helper methods (`current_variant`, `detected_variants`, `variant_preview_active?`, `can_preview_variants?`)
- **`app/helpers/action_version_preview/switcher_helper.rb`** - Provides `variant_switcher` helper that renders the switcher partial

### How It Works

1. Engine initializer includes `ControllerMethods` in all controllers via `ActiveSupport.on_load(:action_controller_base)`
2. `before_action :set_view_variant` checks for the `vv` param (configurable)
3. If param present and user passes `access_check`, sets `request.variant`
4. Rails' template resolver automatically finds `action.html+variant.erb` files
5. `detected_variants` scans view directory for `*.html+*.erb` files, excluding standard Rails variants (mobile, tablet, phone, desktop)

### Dummy App

The `test/dummy/` directory contains a minimal Rails app for testing. Tests use Minitest with `ActionDispatch::IntegrationTest`.

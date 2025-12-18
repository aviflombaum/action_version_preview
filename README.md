# ActionVersionPreview

Preview multiple versions of your UI simultaneously using Rails' built-in view variants. No feature flags, no complex setup. Just create variant templates and visit them via URL.

## Why?

Feature flag gems like Flipper are designed for toggling features on/off for users, not for showing multiple versions at once. For design iterations and feedback collection, you want to open three browser tabs side by side, each showing a different version, all logged in as the same user.

ActionVersionPreview makes this trivial using Rails' native view variants.

<img width="2146" height="2014" alt="image" src="https://github.com/user-attachments/assets/c39b1305-ad14-4958-be39-d714d53d1990" />

[Read more about why I built this...](https://code.avi.nyc/design-previews-for-ruby-on-rails)

## Installation

Add to your Gemfile:

```ruby
gem "action_version_preview"
```

Run `bundle install`. That's it. The concern is automatically included in all controllers.

## Usage

### 1. Create Variant Templates

Rails looks for variant templates using this naming convention:

```
app/views/dashboard/show.html.erb           # default
app/views/dashboard/show.html+v2.erb        # variant :v2
app/views/dashboard/show.html+redesign.erb  # variant :redesign
```

This works for layouts, partials, mailers, and ViewComponent templates too.

### 2. Visit the Variant URL

```
/dashboard           # renders show.html.erb
/dashboard?vv=v2     # renders show.html+v2.erb
/dashboard?vv=true   # renders default, but activates the switcher
```

### 3. Add the Variant Switcher (Optional)

Drop the built-in switcher widget in your layout:

```erb
<%= variant_switcher %>
```

The switcher automatically detects available variants by scanning the view directory for `+variant` template files. It only appears when:
- The `vv` param is present in the URL (e.g., `?vv=true` or `?vv=v2`)
- The current action has variant templates available
- The user can preview variants (dev/test by default)

Standard Rails variants (`mobile`, `tablet`, `phone`, `desktop`) are excluded from detection.

## Configuration

Zero config is the default. But if you need to customize:

```ruby
# config/initializers/action_version_preview.rb
ActionVersionPreview.configure do |config|
  # Change the URL parameter (default: :vv)
  config.param_name = :v

  # Control who can preview variants (default: dev/test only)
  # In production, you might want admins only:
  config.access_check = ->(controller) {
    Rails.env.development? ||
    Rails.env.test? ||
    controller.current_user&.admin?
  }
end
```

## Helper Methods

These are available in controllers and views:

| Method | Description |
|--------|-------------|
| `current_variant` | Returns the active variant symbol (e.g., `:v2`) or `nil` |
| `detected_variants` | Returns array of variant names found for current action |
| `variant_preview_active?` | Returns true if variant preview mode is active |
| `can_preview_variants?` | Returns true if current user can access variants |
| `variant_switcher` | Renders the switcher widget |

## How It Works

Under the hood, ActionVersionPreview sets `request.variant` based on the URL parameter. Rails' template resolver then automatically looks for matching variant templates.

When you visit `/dashboard?vv=v2`:
1. The `before_action` extracts `vv=v2` from params
2. It sets `request.variant = :v2`
3. Rails renders `show.html+v2.erb` instead of `show.html.erb`
4. The switcher detects all `show.html+*.erb` variants in the view directory

## Comparison: Feature Flags vs View Variants

| Feature Flags (Flipper) | View Variants (This Gem) |
|------------------------|--------------------------|
| Toggle features on/off for users | Access all versions simultaneously |
| One version "live" at a time | Side-by-side comparison in multiple tabs |
| Percentage rollouts, A/B testing | Design iteration, feedback collection |
| Requires database/Redis | Zero dependencies |

## Requirements

- Rails 7.0+ or 8.x
- Ruby 3.1+

## License

MIT License. See [MIT-LICENSE](MIT-LICENSE).

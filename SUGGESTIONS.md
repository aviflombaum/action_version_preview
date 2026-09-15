# Feature Suggestions

Ideas for future releases. These are not implemented in 0.2.0. For current behavior, see the [usage guide](docs/usage.md).

## Variant Persistence Across Navigation

Add `default_url_options` override to persist the variant param across all generated URLs. This would let you navigate through your app while staying in a variant.

```ruby
# Would add ?vv=v2 to all link_to, url_for, redirect_to calls
def default_url_options
  return {} unless current_variant
  { ActionVersionPreview.param_name => current_variant }
end
```

**Trade-off:** Variants are typically action-specific, so this might not be desired behavior.

## Disallowed Variants

If there's a security concern about users probing for variant templates, add a disallow list:

```ruby
ActionVersionPreview.configure do |config|
  config.disallowed_variants = %w[admin internal debug]
end
```

**Note:** This configuration is only a proposal. In 0.2.0, `access_check` controls preview selection, and an existing variant can be rendered directly even if its name is hidden from discovery. Keep normal application authorization in place.

## Variant Detection for Partials

Extend `detected_variants` to also scan for partial variants used in the current view. Would require parsing the view to find `render` calls.

## Stimulus Controller for Switcher

Add optional JavaScript behavior:

- Keyboard shortcut to toggle switcher visibility
- Dropdown menu instead of inline buttons
- Remember last used variant in localStorage

## ViewComponent Support

Ensure variant detection works with ViewComponent's file structure (`app/components/`).

## Layout Variant Detection

Detect variants for the current layout file, not just the action template.

## Variant Annotations

Add support for variant metadata via comments in template files:

```erb
<%# variant: name="Redesign 2024", description="New nav and footer" %>
```

Display this in the switcher for better context.

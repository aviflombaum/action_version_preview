# ActionVersionPreview usage guide

This guide describes the public behavior of ActionVersionPreview 0.2.0. The gem
lets you compare Rails UI designs by selecting a view variant for an individual
request. It does not assign visitors to experiments or store a selected design in
a session.

## Installation

Add the gem to an application's Gemfile:

```ruby
gem "action_version_preview", "~> 0.2.0"
```

Run `bundle install` and restart Rails. You do not need to mount routes, run
migrations, generate configuration, or install JavaScript. Controllers inheriting
from `ActionController::Base` receive the preview behavior automatically. The
switcher is optional; variant URLs work without it.

The gem declares Ruby >= 3.1 and Rails >= 7.0, < 9.0. Choose a Ruby version supported
by your Rails release. API-only controllers inheriting directly from
`ActionController::API` are outside the automatic integration.

## Create your first preview

Suppose your application already renders `DashboardController#show` at
`/dashboard`. Keep the default view and add a variant:

```text
app/views/dashboard/show.html.erb
app/views/dashboard/show.html+v2.erb
```

For example, the variant might contain:

```erb
<h1>A new dashboard design</h1>
<%= render "summary" %>
```

Visit `/dashboard?vv=v2` in development. Open `/dashboard` in another tab to compare
the original. Both requests use your normal controller action, authentication,
and data; only template selection changes.

Add more files such as `show.html+redesign.erb` as needed. The name after `+` is
case-sensitive. Lowercase letters, digits, and underscores work with the built-in
discovery, for example `v2`, `redesign`, and `new_layout`.

Rails performs the actual [variant template selection](https://guides.rubyonrails.org/layouts_and_rendering.html#the-variants-option).
If an action has no matching variant template but does have a normal template,
Rails can fall back to that normal template. Selecting a name does not prove a
matching template was rendered.

## URL behavior

These examples use the default parameter name, `vv`, and assume access is allowed:

| Request | Behavior |
| --- | --- |
| `/dashboard` | Leaves normal application variant selection unchanged |
| `/dashboard?vv=v2` | Sets the request variant to `v2` |
| `/dashboard?vv=true` | Enables preview mode without changing the request variant |
| `/dashboard?vv=` | Does not enable preview mode or change the request variant |
| `/dashboard?vv=unknown` | Requests `unknown`; Rails may render the default template |

`true` is a reserved trigger string. It cannot be used to select a template variant
named `true` through this parameter. `false` is an ordinary variant name, not a
switch to disable previews. Remove the parameter to leave preview mode.

Use scalar strings. In 0.2.0, array/hash forms such as `vv[]=v2` or `vv[name]=v2`
are unsupported and may raise an exception when access is allowed. Malformed-input
handling is a separate planned improvement.

When access is denied, the gem leaves the request variant unchanged and hides the
switcher. It does not render an access-denied page or change the response status.

## Add the switcher

Place this inside an HTML layout, usually near the closing `</body>` tag:

```erb
<%= variant_switcher %>
```

The widget appears when all three conditions hold:

1. The configured preview parameter has a nonblank value.
2. The access check permits the request.
3. The current action has discoverable variant templates.

It works when `config.action_controller.include_all_helpers = false`. It uses
ordinary links and inline styles, with no JavaScript dependency.

### Switching and returning to Default

A variant link selects that name on the current path. Other query data, including
nested filters and pagination, is preserved. For example:

```text
/reports?page=2&vv=v2
/reports?page=2&vv=redesign
```

Mounted application prefixes are preserved. Query keys that happen to be named
`host`, `protocol`, or `script_name` remain query data and cannot override the link
destination. Request-body fields are not copied into the links.

**Default** removes the preview parameter. The resulting page follows your normal
application rendering and the switcher disappears. Use `?vv=true` to show it again.
There is no separate persistent preview session or exit button in 0.2.0.

The highlighted link reflects `current_variant`, the request's first variant.
If the requested variant falls back to the normal template, the highlight is not
a report of the template Rails ultimately rendered.

### Styling

The supplied widget is fixed at the bottom-right of the viewport and uses inline
styles. A Content Security Policy that disallows style attributes can prevent
those styles from applying. There are no theme or position configuration options
in 0.2.0. You can override the engine partial in your host application at:

```text
app/views/action_version_preview/_variant_switcher.html.erb
```

Keep application-specific overrides under review when upgrading. Custom styles
and markup are your application's responsibility.

## Configuration

Configure the gem once at application startup:

```ruby
# config/initializers/action_version_preview.rb
ActionVersionPreview.configure do |config|
  config.param_name = :design
end
```

You can then use `/dashboard?design=v2` or `/dashboard?design=true`. The switcher
uses the configured name for every link. Strings and symbols are both accepted.
Choose a name that does not conflict with your application's existing parameters.
Configuration is application-wide, not per-user or per-request.

### Access control and callback order

The default check allows only `Rails.env.development?` or `Rails.env.test?`.
Production, staging, and custom environments are disabled by default. To allow
administrators as well:

```ruby
ActionVersionPreview.configure do |config|
  config.access_check = ->(controller) {
    Rails.env.development? || Rails.env.test? ||
      (controller.respond_to?(:current_user, true) &&
        controller.send(:current_user)&.admin?)
  }
end
```

The callable receives the current controller. A truthy return value allows
previewing; `false` or `nil` denies it. The example supports a private
`current_user` method, but you must adapt the method and permission check to your
application. Avoid performing side effects: the check can run during variant
selection and again while rendering helpers.

The gem registers its callback on `ActionController::Base`. A user lookup that
happens only in a later host `before_action` may not be ready when selection runs.
Prefer a current-user lookup that can resolve its own state when called. If your
authentication requires a callback first, order that callback before preview
selection using Rails' callback ordering facilities, and test the request in your
host application. The gem has no callback-order configuration setting in 0.2.0.

Keep your normal authorization checks for data and actions. The preview access
check governs selection through this gem; it is not a replacement for host
application authorization. Excluding a name from the widget is not an access rule.

## Template discovery

The built-in switcher scans:

```text
app/views/<controller_path>/<action_name>.html+<variant>.erb
```

For example, `Admin::ReportsController#index` is scanned under
`app/views/admin/reports/index.html+*.erb`. Names are returned in sorted order and
cached for that request.

The following names are omitted from the widget: `mobile`, `tablet`, `phone`, and
`desktop`. These are the gem's device-name convention, not names reserved by Rails.
An authorized `?vv=mobile` request can still select a mobile template.

In 0.2.0, automatic discovery does not enumerate:

- Layout-only or partial-only variants.
- Templates in engine-owned or custom/prepended view directories.
- Locale-qualified filenames such as `show.en.html+v2.erb`.
- Handlers other than ERB, such as Haml or Slim.
- Variant names containing hyphens or other characters outside letters, digits,
  and underscores.
- A different template explicitly rendered by the action.

Rails may still render these variants when selected directly by URL. Discovery
controls the widget's choices; it is not an allowlist for request variants.

## Layouts, partials, and components

Native Rails rendering can apply the selected variant to layouts and partials.
For example, a request selecting `v2` can use these files where your normal render
calls refer to them:

```text
app/views/layouts/application.html+v2.erb
app/views/dashboard/_summary.html+v2.erb
```

The switcher does not discover a `v2` choice from those files alone. Use the URL
directly, or also provide an action variant when you want automatic discovery.

ViewComponent and other rendering libraries have their own variant behavior.
ActionVersionPreview sets `request.variant`; it does not scan component directories
or provide a dedicated component integration. Test component rendering in your
host application.

Mailers and background jobs do not automatically inherit the preview URL or its
variant. Pass and select the desired variant in those systems separately.

## Navigation and existing application variants

Selection lasts for the current request. Normal links, redirects, form submissions,
and Turbo requests only keep preview mode if their destination includes the
configured parameter. The gem does not modify `default_url_options`, cookies,
sessions, localStorage, or Turbo behavior.

For a link where you explicitly want to carry the current variant forward, add it
with your application's route helper:

```erb
<%= link_to "Reports", reports_path(design: current_variant) %>
```

This example assumes `config.param_name = :design`. If you want to open the
switcher without selecting a variant, pass `design: "true"` instead. Consider
whether the destination action actually has the same variants.

A nonblank preview name replaces the request's variant selection. Missing/blank
parameters, denied access, and the `true` trigger leave an existing application
variant unchanged. Other controller callbacks can still change it later.

## Helper reference

| Method | Available in | Meaning |
| --- | --- | --- |
| `variant_switcher` | Views | Renders the built-in widget, or no visible widget when its conditions are not met |
| `current_variant` | Controller and views | First request variant as a symbol, or `nil` |
| `detected_variants` | Controller and views | Sorted array of discovered names as strings |
| `variant_preview_active?` | Controller and views | Truthy when the parameter is nonblank and access is allowed |
| `can_preview_variants?` | Controller and views | Result of the configured access check |

The controller methods are private and exposed as view helpers. Use the widget
or normal Rails route helpers for your own links.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| No switcher | Include the helper, provide `vv=true`, allow access, and check that action ERB variants are discoverable |
| Works locally but not in staging | Configure `access_check`; staging is denied by default |
| Requested variant renders the original view | Check spelling, case, filename, access, callback order, and Rails fallback behavior |
| Default makes the switcher disappear | Expected in 0.2.0; Default removes the parameter |
| Variant disappears after navigation | Include the preview parameter in that destination if you want to retain it |
| Device variant changes unexpectedly | A concrete preview name replaces the request variant; check other callbacks too |
| Widget is unstyled | Check the host's Content Security Policy and any partial override |
| 0.1.0 raises `SwitcherHelper` during asset precompilation | Upgrade to 0.2.0, update the lockfile, and rebuild the deployment image |

## Upgrading from 0.1.0

Update your version constraint if it pins 0.1.0, then run:

```sh
bundle update action_version_preview
```

Restart Rails or rebuild your deployment image so it installs the new lockfile
resolution. No migration, route mount, or new initializer is required.

0.2.0 fixes helper loading during boot and asset precompilation, and changes the
built-in switcher to derive URLs from the current path and query data. POST body
fields no longer appear in its links. The configuration names, default access
policy, discovery scope, and Default behavior remain the same.

See the [changelog](../CHANGELOG.md) and [release notes](releases/0.2.0.md).

# ActionVersionPreview

Preview multiple versions of a Rails UI in separate browser tabs using native
view variants. Add variant templates, open their URLs, and compare designs while
signed in as the same user. No additional database, feature-flag service, or
JavaScript is required.

[Full usage guide](docs/usage.md) · [Changelog](CHANGELOG.md) · [RubyGems](https://rubygems.org/gems/action_version_preview)

## Install

Add the gem to your Rails application's Gemfile:

```ruby
gem "action_version_preview", "~> 0.2.0"
```

Run `bundle install` and restart the application. No generator or engine mount is
needed. Preview selection is added to controllers inheriting from
`ActionController::Base`.

## Quick start

### 1. Create variant templates

For a `DashboardController#show` action, keep a default template and add variants:

```text
app/views/dashboard/show.html.erb
app/views/dashboard/show.html+v2.erb
app/views/dashboard/show.html+redesign.erb
```

Use names such as `v2`, `redesign`, or `new_layout` for automatic switcher discovery.

### 2. Open the preview URLs

In development or test:

| URL | Result |
| --- | --- |
| `/dashboard` | Normal rendering |
| `/dashboard?vv=v2` | Selects the `v2` variant |
| `/dashboard?vv=redesign` | Selects the `redesign` variant |
| `/dashboard?vv=true` | Enables the switcher without selecting a variant |

The last example keeps any variant your application already set, such as a mobile
variant. Otherwise it renders the default template.

### 3. Add the optional switcher

Put this near the end of your application layout's body:

```erb
<%= variant_switcher %>
```

The switcher appears only when preview mode is requested, access is allowed, and
variant templates are discovered for the current action. Its links preserve the
current path, mounted prefix, and query filters. **Default** removes the preview
parameter and closes the switcher. Add `?vv=true` again to reopen it.

Automatic discovery in 0.2.0 covers HTML ERB action templates in the host app's
`app/views/<controller_path>` directory. See the [discovery limits](docs/usage.md#template-discovery)
for layouts, partials, other handlers, and engine views.

## Enable previews for your users

By default, previews are enabled only in development and test. Production,
staging, and other environments deny preview selection until you configure access.

```ruby
# config/initializers/action_version_preview.rb
ActionVersionPreview.configure do |config|
  config.param_name = :vv # Optional; a string also works.
  config.access_check = ->(controller) {
    Rails.env.development? || Rails.env.test? ||
      (controller.respond_to?(:current_user, true) &&
        controller.send(:current_user)&.admin?)
  }
end
```

Adapt `current_user` and `admin?` to your authentication system. The example also
works when `current_user` is private. Your user/context must be available when the
preview callback runs; see [access control and callback order](docs/usage.md#access-control-and-callback-order).

The preview parameter applies to one request. Links and redirects elsewhere in
your app do not inherit it automatically. Ordinary application authorization still
controls access to data and actions.

## What's new in 0.2.0

- Fixes `ActionVersionPreview::SwitcherHelper` load-order errors during application
  boot and asset precompilation, including early controller/view loading.
- Keeps switcher links on the current request path. Query keys such as `host` and
  `protocol` remain query data; POST body fields are not copied into URLs.
- Adds boot, reload, packaged-gem precompilation, and switcher URL regression tests.

To upgrade from 0.1.0, update your Gemfile constraint if necessary, run
`bundle update action_version_preview`, and rebuild/restart the application.
No migration or configuration change is required. Read the [0.2.0 release notes](docs/releases/0.2.0.md).

## Compatibility

- Declared requirements: Ruby **3.1+**, Rails **7.0 or later, below 9.0**.
- Each Rails version may require a newer Ruby; the reviewed Rails 8.1 bundle
  requires Ruby 3.2+.
- Release validation used Ruby 4.0.5 with Rails 8.1.3.1. CI is configured for Ruby
  3.4.7. A full matrix of the declared versions is not yet in place.
- Automatic controller integration targets `ActionController::Base`, not API-only
  controllers inheriting directly from `ActionController::API`.

## Development

```sh
bundle install
bin/rails test
bin/rubocop
RAILS_ENV=test bundle exec rake app:zeitwerk:check
bundle exec rake build
```

The test suite includes an isolated host that installs the built gem and compiles
assets in production mode. See the [release procedure](docs/releasing.md) for
security scans and publication.

## Background

[Why I built design previews for Rails](https://code.avi.nyc/design-previews-for-ruby-on-rails)

<img width="2146" height="2014" alt="Several Rails UI variants displayed for comparison" src="https://github.com/user-attachments/assets/c39b1305-ad14-4958-be39-d714d53d1990" />

## License

[MIT License](MIT-LICENSE).

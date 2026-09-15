# Run in a fresh Ruby process: the parent's Rails app has already initialized.
require "bundler/setup"
require "tmpdir"
require "fileutils"
require "rails"
require "action_controller/railtie"
require "action_view/railtie"

gem_root, mode = ARGV
gem_root = File.realpath(gem_root)
# Keep the installed-package test from falling back to the checkout's library.
$LOAD_PATH.delete(File.expand_path("../../lib", __dir__))
$LOAD_PATH.unshift(File.join(gem_root, "lib"))

if mode != "lazy"
  ActionController::Base
  ActionView::Base
end

require "action_version_preview"
require "propshaft" if mode == "production"

Dir.mktmpdir("action-version-preview-host") do |root|
  %w[config app/controllers app/views/previews app/views/layouts app/assets/stylesheets].each do |directory|
    FileUtils.mkdir_p(File.join(root, directory))
  end
  File.write(File.join(root, "app/controllers/previews_controller.rb"), <<~RUBY)
    class PreviewsController < ActionController::Base
      layout "application"

      def index
      end
    end
  RUBY
  File.write(File.join(root, "app/views/layouts/application.html.erb"), "<%= yield %><%= variant_switcher %>")
  File.write(File.join(root, "app/views/previews/index.html.erb"), "Default preview")
  File.write(File.join(root, "app/views/previews/index.html+v2.erb"), "V2 preview")
  File.write(File.join(root, "app/assets/stylesheets/application.css"), "body { color: black; }")
  File.write(File.join(root, "config/routes.rb"), 'Rails.application.routes.draw { get "/previews", to: "previews#index" }')

  app_class = Class.new(Rails::Application) do
    config.root = root
    config.eager_load = mode == "production"
    config.cache_classes = mode != "reload"
    config.action_controller.include_all_helpers = false
    config.action_dispatch.show_exceptions = :none
    config.hosts.clear
    config.logger = Logger.new(File::NULL)
    config.secret_key_base = "boot-test" * 16 unless mode == "production"
  end
  Object.const_set(:BootHostApplication, app_class)
  app = app_class.initialize!
  ActionVersionPreview.access_check = ->(_) { true }

  raise "Engine loaded from the wrong source" unless File.realpath(ActionVersionPreview::Engine.root) == gem_root
  helper_source = ActionVersionPreview::SwitcherHelper.instance_method(:variant_switcher).source_location.first
  raise "Helper loaded from the wrong source" unless File.realpath(helper_source).start_with?("#{gem_root}/")

  render_switcher = -> {
    response = Rack::MockRequest.new(app).get("/previews?vv=v2")
    unless response.status == 200 && response.body.include?("V2 preview") && response.body.include?("vv=v2") && response.body.include?(">Default</a>")
      raise "Switcher rendering failed: #{response.status}\n#{response.body}"
    end
  }
  if mode == "production"
    app.load_tasks
    Rake::Task["assets:precompile"].invoke
    manifest = File.join(root, "public/assets/.manifest.json")
    raise "Assets were not compiled" unless File.exist?(manifest) && File.read(manifest).include?("application.css")
  end

  render_switcher.call

  if mode == "reload"
    app.reloader.reload!
    render_switcher.call
  end

  puts "Boot, render, and #{mode} checks passed"
end

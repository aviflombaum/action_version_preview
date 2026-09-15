require "test_helper"
require "open3"
require "tmpdir"
require "rubygems/package"
require "rubygems/installer"

class BootTest < ActiveSupport::TestCase
  ROOT = File.expand_path("../..", __dir__)
  HOST = File.join(ROOT, "test/support/boot_host.rb")

  test "boots and renders with Action Controller and Action View already loaded" do
    assert_host_boots(ROOT, "early")
  end

  test "boots and renders with lazy framework loading" do
    assert_host_boots(ROOT, "lazy")
  end

  test "switcher remains available after reloading" do
    assert_host_boots(ROOT, "reload")
  end

  test "installed gem boots and precompiles assets with early framework loading" do
    Dir.mktmpdir("action-version-preview-package") do |directory|
      package = File.join(directory, "action_version_preview.gem")
      capture_io do
        Dir.chdir(ROOT) do
          spec = Gem::Specification.load("action_version_preview.gemspec")
          Gem::Package.build(spec, false, false, package)
        end
      end
      installed = Gem::Installer.at(package, install_dir: File.join(directory, "gems"), ignore_dependencies: true, wrappers: false).install
      assert_host_boots(installed.full_gem_path, "production")
    end
  end

  private

  def assert_host_boots(gem_root, mode)
    output, status = Open3.capture2e(
      { "RAILS_ENV" => mode == "production" ? "production" : "test", "SECRET_KEY_BASE_DUMMY" => "1", "SECRET_KEY_BASE" => nil },
      RbConfig.ruby, HOST, gem_root, mode
    )
    assert status.success?, output
  end
end

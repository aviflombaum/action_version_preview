require "test_helper"

class ActionVersionPreviewTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert ActionVersionPreview::VERSION
  end

  test "default param_name is :vv" do
    assert_equal :vv, ActionVersionPreview.param_name
  end

  test "default allowed_variants includes v2, v3, redesign" do
    assert_includes ActionVersionPreview.allowed_variants, "v2"
    assert_includes ActionVersionPreview.allowed_variants, "v3"
    assert_includes ActionVersionPreview.allowed_variants, "redesign"
  end

  test "configure block allows setting options" do
    original_param = ActionVersionPreview.param_name
    original_variants = ActionVersionPreview.allowed_variants.dup

    ActionVersionPreview.configure do |config|
      config.param_name = :variant
      config.allowed_variants = %w[beta alpha]
    end

    assert_equal :variant, ActionVersionPreview.param_name
    assert_equal %w[beta alpha], ActionVersionPreview.allowed_variants

    # Reset
    ActionVersionPreview.param_name = original_param
    ActionVersionPreview.allowed_variants = original_variants
  end

  test "access_check returns true in test environment by default" do
    controller = Object.new
    assert ActionVersionPreview.access_check.call(controller)
  end
end

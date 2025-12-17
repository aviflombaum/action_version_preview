require "test_helper"

class ActionVersionPreviewTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert ActionVersionPreview::VERSION
  end

  test "default param_name is :vv" do
    assert_equal :vv, ActionVersionPreview.param_name
  end

  test "configure block allows setting param_name" do
    original_param = ActionVersionPreview.param_name

    ActionVersionPreview.configure do |config|
      config.param_name = :variant
    end

    assert_equal :variant, ActionVersionPreview.param_name

    # Reset
    ActionVersionPreview.param_name = original_param
  end

  test "access_check returns true in test environment by default" do
    controller = Object.new
    assert ActionVersionPreview.access_check.call(controller)
  end

  test "STANDARD_VARIANTS includes mobile, tablet, phone, desktop" do
    standard = ActionVersionPreview::ControllerMethods::STANDARD_VARIANTS
    assert_includes standard, "mobile"
    assert_includes standard, "tablet"
    assert_includes standard, "phone"
    assert_includes standard, "desktop"
  end
end

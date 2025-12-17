require "test_helper"

class VariantPreviewTest < ActionDispatch::IntegrationTest
  # detected_variants tests

  test "detected_variants finds variant files for current action" do
    get posts_path(vv: "true")
    assert_response :success

    # Should find v2 and redesign, but not mobile (standard variant)
    variants = @controller.send(:detected_variants)
    assert_includes variants, "v2"
    assert_includes variants, "redesign"
    refute_includes variants, "mobile"
  end

  test "detected_variants returns empty array when no variants exist" do
    get post_path(id: 1, vv: "true")
    assert_response :success

    variants = @controller.send(:detected_variants)
    assert_equal [], variants
  end

  test "detected_variants excludes all standard Rails variants" do
    get posts_path(vv: "true")

    variants = @controller.send(:detected_variants)
    ActionVersionPreview::ControllerMethods::STANDARD_VARIANTS.each do |standard|
      refute_includes variants, standard
    end
  end

  # variant_preview_active? tests

  test "variant_preview_active? returns true when param is present" do
    get posts_path(vv: "true")
    assert @controller.send(:variant_preview_active?)
  end

  test "variant_preview_active? returns true with variant value" do
    get posts_path(vv: "v2")
    assert @controller.send(:variant_preview_active?)
  end

  test "variant_preview_active? returns false when param is absent" do
    get posts_path
    refute @controller.send(:variant_preview_active?)
  end

  # Variant rendering tests

  test "renders default view without vv param" do
    get posts_path
    assert_response :success
    assert_match "Posts Index - Default", response.body
  end

  test "renders v2 variant with vv=v2" do
    get posts_path(vv: "v2")
    assert_response :success
    assert_match "Posts Index - V2", response.body
  end

  test "renders default view with vv=true (activates switcher only)" do
    get posts_path(vv: "true")
    assert_response :success
    assert_match "Posts Index - Default", response.body
  end
end

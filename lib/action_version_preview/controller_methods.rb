module ActionVersionPreview
  module ControllerMethods
    extend ActiveSupport::Concern

    # Standard Rails variants that should be excluded from detection
    STANDARD_VARIANTS = %w[mobile tablet phone desktop].freeze

    included do
      before_action :set_view_variant
      helper_method :current_variant, :detected_variants, :can_preview_variants?, :variant_preview_active?
    end

    private

    def set_view_variant
      variant = params[ActionVersionPreview.param_name]
      return unless variant.present?
      return unless can_preview_variants?

      # Set the variant if it's not just a truthy trigger value
      request.variant = variant.to_sym unless variant.to_s == "true"
    end

    def current_variant
      request.variant&.first
    end

    # Returns true if the variant preview mode is active (param is present)
    def variant_preview_active?
      params[ActionVersionPreview.param_name].present? && can_preview_variants?
    end

    # Auto-detect variant files for the current controller action
    def detected_variants
      @detected_variants ||= begin
        view_path = Rails.root.join("app", "views", controller_path)
        pattern = "#{action_name}.html+*.erb"

        Dir.glob(view_path.join(pattern)).filter_map do |file|
          match = File.basename(file).match(/\.html\+(\w+)\.erb$/)
          variant = match[1] if match
          variant unless STANDARD_VARIANTS.include?(variant)
        end.sort
      end
    end

    def can_preview_variants?
      ActionVersionPreview.access_check.call(self)
    end
  end
end

module ActionVersionPreview
  module ControllerMethods
    extend ActiveSupport::Concern

    included do
      before_action :set_view_variant
      helper_method :current_variant, :available_variants, :can_preview_variants?
    end

    private

    def set_view_variant
      variant = params[ActionVersionPreview.param_name]
      return unless variant.present?
      return unless can_preview_variants?
      return unless allowed_variant?(variant)

      request.variant = variant.to_sym
    end

    def current_variant
      request.variant&.first
    end

    def available_variants
      ActionVersionPreview.allowed_variants
    end

    def can_preview_variants?
      ActionVersionPreview.access_check.call(self)
    end

    def allowed_variant?(variant)
      available_variants.include?(variant.to_s)
    end

    # Override default_url_options to persist variant across navigation
    def default_url_options
      options = super rescue {}
      return options unless current_variant

      options.merge(ActionVersionPreview.param_name => current_variant)
    end
  end
end

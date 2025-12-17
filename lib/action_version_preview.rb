require "action_version_preview/version"
require "action_version_preview/engine"

module ActionVersionPreview
  class << self
    # The URL parameter name used to specify the variant (default: :vv)
    # Example: /dashboard?vv=v2
    attr_accessor :param_name

    # List of allowed variant names (default: %w[v2 v3 redesign])
    # Only these variants can be activated via URL parameter
    attr_accessor :allowed_variants

    # Proc that determines if the current user can preview variants
    # Default: always true in development/test, always false in production
    # Example: ->(controller) { controller.current_user&.admin? }
    attr_accessor :access_check
  end

  # Set sensible defaults
  self.param_name = :vv
  self.allowed_variants = %w[v2 v3 redesign]
  self.access_check = ->(controller) {
    Rails.env.development? || Rails.env.test?
  }

  def self.configure
    yield self
  end
end

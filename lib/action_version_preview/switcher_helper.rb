module ActionVersionPreview
  # Required by the engine: load hooks may run before Rails sets up autoloading.
  module SwitcherHelper
    def variant_switcher
      render partial: "action_version_preview/variant_switcher"
    end
  end
end

module ActionVersionPreview
  # Required by the engine: load hooks may run before Rails sets up autoloading.
  module SwitcherHelper
    def variant_switcher
      render partial: "action_version_preview/variant_switcher"
    end

    private

    def variant_preview_path(variant = nil)
      param_name = ActionVersionPreview.param_name.to_s
      query = request.query_parameters.except(param_name)
      query[param_name] = variant if variant

      query.empty? ? request.path : "#{request.path}?#{query.to_query}"
    end
  end
end

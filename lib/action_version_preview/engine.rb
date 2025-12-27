require "action_version_preview/controller_methods"

module ActionVersionPreview
  class Engine < ::Rails::Engine
    isolate_namespace ActionVersionPreview

    initializer "action_version_preview.controller_methods" do
      ActiveSupport.on_load(:action_controller_base) do
        include ActionVersionPreview::ControllerMethods
      end
    end

    initializer "action_version_preview.helpers", after: :load_config_initializers do
      ActiveSupport.on_load(:action_view) do
        include ActionVersionPreview::SwitcherHelper
      end
    end
  end
end

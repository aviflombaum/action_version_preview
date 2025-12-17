require "action_version_preview/controller_methods"

module ActionVersionPreview
  class Engine < ::Rails::Engine
    isolate_namespace ActionVersionPreview

    initializer "action_version_preview.controller_methods" do
      ActiveSupport.on_load(:action_controller_base) do
        include ActionVersionPreview::ControllerMethods
        helper ActionVersionPreview::Engine.helpers
      end
    end
  end
end

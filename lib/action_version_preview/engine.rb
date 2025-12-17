require "action_version_preview/controller_methods"

module ActionVersionPreview
  class Engine < ::Rails::Engine
    isolate_namespace ActionVersionPreview

    # Make helpers available to the host application
    initializer "action_version_preview.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper ActionVersionPreview::Engine.helpers
      end
    end
  end
end

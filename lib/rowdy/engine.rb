require "turbo-rails"

module Rowdy
  class Engine < ::Rails::Engine
    isolate_namespace Rowdy

    config.autoload_paths << root.join("app/components")

    # Load translations from engine
    config.before_initialize do
      I18n.load_path += Dir[Engine.root.join("config", "locales", "**", "*.yml")]
    end

    initializer "rowdy.view_component" do
      ActiveSupport.on_load(:action_view) do
        require "view_component"
      end
    end

    initializer "rowdy.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.paths << root.join("app/assets/stylesheets")
      end
    end

    initializer "rowdy.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end

    initializer :append_migrations do |app|
      unless app.root.to_s == root.to_s
        app.config.paths["db/migrate"].concat(config.paths["db/migrate"].existent)
      end
    end
  end
end

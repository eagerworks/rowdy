require "rails/generators"
require_relative "messages"

module Rowdy
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Messages

      desc "Installs Rowdy into the host application."

      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "rowdy.rb", "config/initializers/rowdy.rb"
      end

      def mount_engine
        route 'mount Rowdy::Engine => "/rowdy"'
      end

      def inject_stylesheet
        layout = "app/views/layouts/application.html.erb"
        layout_path = File.join(destination_root, layout)

        unless File.exist?(layout_path)
          stylesheet_file_does_not_exist_warning(layout)
          return
        end

        content = File.read(layout_path)

        if content.include?("rowdy/application")
          stylesheet_already_exists_message(layout)
          return
        end

        inject_into_file layout, after: /stylesheet_link_tag.*\n/ do
          "    <%= stylesheet_link_tag \"rowdy/application\", \"data-turbo-track\": \"reload\" %>\n"
        end
      end

      def check_queues
        check_queues_message
      end

      def check_action_cable
        cable_yml = File.join(destination_root, "config/cable.yml")

        unless File.exist?(cable_yml)
          action_cable_file_does_not_exist_warning
          return
        end

        content = File.read(cable_yml)
        development_section = content[/development:.*?(?=\n\w|\z)/m]

        if development_section&.include?("adapter: async")
          action_cable_async_adapter_warning
        else
          action_cable_success
        end
      end

      def copy_migrations
        rails_command "active_storage:install"
        rails_command "rowdy:install:migrations"
        migrations_message
      end

      def install
        if importmap?
          install_importmap
        elsif jsbundling?
          install_jsbundling
        else
          js_setup_warning
        end
      end

      private

      def importmap?
        File.exist?(File.join(destination_root, "config/importmap.rb"))
      end

      def jsbundling?
        File.exist?(File.join(destination_root, "package.json"))
      end

      def install_importmap
        js_entrypoint = %w[app/javascript/application.js app/javascript/application.ts]
          .find { File.exist?(File.join(destination_root, _1)) }

        unless js_entrypoint
          js_entrypoint_warning
          return
        end

        content = File.read(File.join(destination_root, js_entrypoint))

        if content.include?('from "rowdy"')
          importmap_already_setup_message(js_entrypoint)
          return
        end

        imports = []
        imports << 'import { application } from "controllers/application"' unless content.include?("controllers/application")
        imports << 'import { install } from "rowdy"'
        imports << "install(application)"

        append_to_file js_entrypoint, "\n#{imports.join("\n")}\n"
        js_success(js_entrypoint)
      end

      def install_jsbundling
        jsbundling_init_message

        gem_path = `bundle show rowdy`.strip
        if gem_path.empty?
          jsbundling_rowdy_gem_missing_error
          return
        end

        run "yarn add file:#{gem_path}"

        js_entrypoint = %w[app/javascript/application.js app/javascript/application.ts]
          .find { File.exist?(File.join(destination_root, _1)) }

        if js_entrypoint
          content = File.read(File.join(destination_root, js_entrypoint))
          unless content.include?('from "rowdy"')
            append_to_file js_entrypoint, <<~JS

              import { install as installRowdy } from "rowdy"
              installRowdy(application)
            JS
            js_success(js_entrypoint)
          end
        else
          js_entrypoint_warning
        end

        run "yarn build"
      end
    end
  end
end

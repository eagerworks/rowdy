require "rails/generators"

module Rowdy
  module Generators
    class InstallGenerator < Rails::Generators::Base
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
          say_status :warning, "Could not find #{layout}. Add this manually to your layout's <head>:", :yellow
          say '  <%= stylesheet_link_tag "rowdy/application", "data-turbo-track": "reload" %>'
          return
        end

        content = File.read(layout_path)

        if content.include?("rowdy/application")
          say_status :stylesheet, "Rowdy stylesheet already present in #{layout} — skipping.", :green
          return
        end

        inject_into_file layout, after: /stylesheet_link_tag.*\n/ do
          "    <%= stylesheet_link_tag \"rowdy/application\", \"data-turbo-track\": \"reload\" %>\n"
        end
      end

      def check_queues
        say ""
        say_status :queues, "Make sure your background job adapter processes these Rowdy queues:", :green
        say "  rowdy_imports"
        say "  rowdy_processing"
        say ""
      end

      def check_action_cable
        cable_yml = File.join(destination_root, "config/cable.yml")

        unless File.exist?(cable_yml)
          say_status :warning, "config/cable.yml not found. Make sure Action Cable is configured with a cross-process adapter (solid_cable or redis).", :yellow
          return
        end

        content = File.read(cable_yml)
        development_section = content[/development:.*?(?=\n\w|\z)/m]

        if development_section&.include?("adapter: async")
          say ""
          say_status :warning, "Action Cable is using the 'async' adapter in development.", :yellow
          say "  The async adapter only works within the same process and will not deliver", :yellow
          say "  Rowdy broadcasts from Sidekiq workers to the browser.", :yellow
          say "  Switch to solid_cable or redis in config/cable.yml:", :yellow
          say ""
          say "  development:"
          say "    adapter: solid_cable"
          say "    connects_to:"
          say "      database:"
          say "        writing: primary"
          say "    polling_interval: 0.1.seconds"
          say "    message_retention: 1.day"
          say ""
        else
          say_status :cable, "Action Cable adapter looks good.", :green
        end
      end

      def copy_migrations
        rails_command "active_storage:install"
        rails_command "rowdy:install:migrations"
        say ""
        say "Run migrations:", :green
        say "  rails db:migrate"
      end

      def install
        if importmap?
          install_importmap
        elsif jsbundling?
          install_jsbundling
        else
          say_status :warning, "Could not detect JS setup (importmap or jsbundling). See README for manual installation.", :yellow
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
          say_status :warning, "Could not find application.js. Add this manually:", :yellow
          print_manual_instructions
          return
        end

        content = File.read(File.join(destination_root, js_entrypoint))

        if content.include?('from "rowdy"')
          say_status :importmap, "Rowdy already installed in #{js_entrypoint} — skipping.", :green
          return
        end

        imports = []
        imports << 'import { application } from "controllers/application"' unless content.include?("controllers/application")
        imports << 'import { install } from "rowdy"'
        imports << "install(application)"

        append_to_file js_entrypoint, "\n#{imports.join("\n")}\n"
        say_status :insert, js_entrypoint, :green
      end

      def install_jsbundling
        say_status :jsbundling, "Adding Rowdy as a local npm package...", :green

        gem_path = `bundle show rowdy`.strip
        if gem_path.empty?
          say_status :error, "Could not find Rowdy gem path. Is it in your Gemfile?", :red
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
            say_status :insert, js_entrypoint, :green
          end
        else
          say_status :warning, "Could not find application.js. Add this manually:", :yellow
          print_manual_instructions
        end

        run "yarn build"
      end

      def print_manual_instructions
        say ""
        say '  import { application } from "controllers/application"'
        say '  import { install } from "rowdy"'
        say "  install(application)"
      end
    end
  end
end

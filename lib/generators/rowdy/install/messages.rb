module Rowdy
  module Generators
    module Messages
      def stylesheet_file_does_not_exist_warning(layout)
        say_status :warning, "Could not find #{layout}. Add this manually to your layout's <head>:", :yellow
        say '  <%= stylesheet_link_tag "rowdy/application", "data-turbo-track": "reload" %>'
      end

      def stylesheet_already_exists_message(layout)
        say_status :stylesheet, "Rowdy stylesheet already present in #{layout} — skipping.", :green
      end

      def check_queues_message
        say
        say_status :queues, "Make sure your background job adapter processes these Rowdy queues:", :green
        say "  rowdy_imports"
        say "  rowdy_processing"
        say
      end

      def action_cable_file_does_not_exist_warning
        say_status :warning, "config/cable.yml not found. Make sure Action Cable is configured with a cross-process adapter (solid_cable or redis).", :yellow
      end

      def action_cable_async_adapter_warning
        say
        say_status :warning, "Action Cable is using the 'async' adapter in development.", :yellow
        say "  The async adapter only works within the same process and will not deliver", :yellow
        say "  Rowdy broadcasts from Sidekiq workers to the browser.", :yellow
        say "  Switch to solid_cable or redis in config/cable.yml:", :yellow
        say
        say "  development:"
        say "    adapter: solid_cable"
        say "    connects_to:"
        say "      database:"
        say "        writing: primary"
        say "    polling_interval: 0.1.seconds"
        say "    message_retention: 1.day"
        say
      end

      def action_cable_success
        say_status :cable, "Action Cable adapter looks good.", :green
      end

      def migrations_message
        say
        say "Run migrations:", :green
        say "  rails db:migrate"
      end

      def js_setup_warning
        say_status :warning, "Could not detect JS setup (importmap or jsbundling). See README for manual installation.", :yellow
      end

      def js_entrypoint_warning
        say_status :warning, "Could not find application.js. Add this manually:", :yellow
        js_manual_inscructions_warning
      end

      def importmap_already_setup_message(js_entrypoint)
        say_status :importmap, "Rowdy already installed in #{js_entrypoint} — skipping.", :green
      end

      def jsbundling_init_message
        say_status :jsbundling, "Adding Rowdy as a local npm package...", :green
      end

      def jsbundling_rowdy_gem_missing_error
        say_status :error, "Could not find Rowdy gem path. Is it in your Gemfile?", :red
      end

      def js_success(js_entrypoint)
        say_status :insert, js_entrypoint, :green
      end

      def js_manual_inscructions_warning
        say
        say '  import { application } from "controllers/application"'
        say '  import { install } from "rowdy"'
        say "  install(application)"
      end
    end
  end
end

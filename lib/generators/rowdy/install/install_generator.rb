require "rails/generators"

module Rowdy
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Installs Rowdy JavaScript assets into the host application."

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
        say_status :importmap, "Rowdy JS is auto-loaded via the engine initializer — nothing to do.", :green
        say ""
        say "Make sure your application.js includes:", :green
        say '  import { install } from "rowdy"'
        say "  install(application)"
      end

      def install_jsbundling
        say_status :jsbundling, "Adding Rowdy as a local npm package...", :green

        gem_path = `bundle show rowdy`.strip
        if gem_path.empty?
          say_status :error, "Could not find Rowdy gem path. Is it in your Gemfile?", :red
          return
        end

        run "yarn add file:#{gem_path}"

        inject_import

        run "yarn build"
      end

      def inject_import
        js_entrypoint = %w[app/javascript/application.js app/javascript/application.ts]
          .find { File.exist?(File.join(destination_root, _1)) }

        unless js_entrypoint
          say_status :warning, "Could not find application.js. Add this manually:", :yellow
          print_manual_instructions
          return
        end

        append_to_file js_entrypoint, <<~JS

          import { install as installRowdy } from "rowdy"
          installRowdy(application)
        JS

        say_status :insert, js_entrypoint, :green
      end

      def print_manual_instructions
        say ""
        say '  import { install as installRowdy } from "rowdy"'
        say "  installRowdy(application)"
      end
    end
  end
end

require "rails_helper"
require "generators/rowdy/install/install_generator"

RSpec.describe Rowdy::Generators::InstallGenerator do
  let(:tmp_dir) { Dir.mktmpdir("rowdy_generator") }

  subject(:generator) { described_class.new([], {}, destination_root: tmp_dir) }

  before do
    allow(generator).to receive(:say)
    allow(generator).to receive(:say_status)
    allow(generator).to receive(:run)
  end

  after { FileUtils.rm_rf(tmp_dir) }

  def create(*paths)
    paths.each do |path|
      full = File.join(tmp_dir, path)
      FileUtils.mkdir_p(File.dirname(full))
      FileUtils.touch(full)
    end
  end

  def read(path)
    File.read(File.join(tmp_dir, path))
  end

  describe "#install" do
    context "with importmap" do
      before do
        create "config/importmap.rb", "app/javascript/application.js"
        generator.install
      end

      it "prints an importmap status message" do
        expect(generator).to have_received(:say_status).with(:insert, anything, :green)
      end

      it "does not run yarn" do
        expect(generator).not_to have_received(:run)
      end
    end

    context "with jsbundling" do
      before do
        create "package.json"
        allow(generator).to receive(:`).with("bundle show rowdy").and_return("/path/to/rowdy\n")
      end

      context "when application.js exists" do
        before do
          create "app/javascript/application.js"
          generator.install
        end

        it "runs yarn add with the gem path" do
          expect(generator).to have_received(:run).with("yarn add file:/path/to/rowdy")
        end

        it "appends the import to application.js" do
          content = read("app/javascript/application.js")
          expect(content).to include('import { install as installRowdy } from "rowdy"')
          expect(content).to include("installRowdy(application)")
        end
      end

      context "when application.ts exists instead" do
        before do
          create "app/javascript/application.ts"
          generator.install
        end

        it "appends the import to application.ts" do
          content = read("app/javascript/application.ts")
          expect(content).to include('import { install as installRowdy } from "rowdy"')
        end
      end

      context "when no application.js or .ts exists" do
        before { generator.install }

        it "prints a warning" do
          expect(generator).to have_received(:say_status).with(:warning, /application\.js/, :yellow)
        end

        it "does not raise" do
          expect { generator.install }.not_to raise_error
        end
      end

      context "when rowdy gem is not found" do
        before do
          allow(generator).to receive(:`).with("bundle show rowdy").and_return("")
          generator.install
        end

        it "prints an error" do
          expect(generator).to have_received(:say_status).with(:error, anything, :red)
        end

        it "does not run yarn" do
          expect(generator).not_to have_received(:run)
        end
      end
    end

    context "with neither importmap nor jsbundling" do
      before { generator.install }

      it "prints a warning" do
        expect(generator).to have_received(:say_status).with(:warning, anything, :yellow)
      end

      it "does not run yarn" do
        expect(generator).not_to have_received(:run)
      end
    end
  end
end

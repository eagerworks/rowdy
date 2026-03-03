require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "../test/dummy/config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "view_component"
require "factory_bot_rails"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_paths = [ File.expand_path("../test/fixtures", __dir__) ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include XlsxHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ViewComponent::TestHelpers, type: :component

  FactoryBot.definition_file_paths = [ File.expand_path("factories", __dir__) ]
  FactoryBot.find_definitions
end

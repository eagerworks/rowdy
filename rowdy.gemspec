require_relative "lib/rowdy/version"

Gem::Specification.new do |spec|
  spec.name        = "rowdy"
  spec.version     = Rowdy::VERSION
  spec.authors     = [ "Rowdy Team" ]
  spec.email       = [ "team@rowdy.dev" ]
  spec.homepage    = "https://github.com/rowdy/rowdy"
  spec.summary     = "Rails engine for asynchronous XLSX file processing"
  spec.description = "Rowdy is a Rails engine that provides a complete system for uploading, processing, and downloading XLSX files asynchronously with progress tracking."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rowdy/rowdy"
  spec.metadata["changelog_uri"] = "https://github.com/rowdy/rowdy/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.2"
  spec.add_dependency "view_component", ">= 3", "< 5"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "creek", "~> 2.6"
end

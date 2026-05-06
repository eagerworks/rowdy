Rails.application.config.to_prepare do
  Rowdy.configure do |config|
    # Required: define how uploaded files are processed.
    # The lambda receives the file path and the upload record.
    # Call progress.call(percent) to report progress (0..100).
    config.processor = lambda do |input_path, upload, &progress|
      # process the file here...
      progress.call(100)
      input_path
    end

    # Optional: register import schemas
    # config.schemas = [ProductImportSchema]

    # Optional: show a custom action button after a successful import
    # config.action_label = "Go to Dashboard"
    # config.action_href = "/dashboard"
    # Use a lambda to build a dynamic URL from the finished import:
    # config.action_href = ->(import) { "/imports/#{import.id}/results" }
  end
end

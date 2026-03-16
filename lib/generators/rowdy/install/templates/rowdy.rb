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
  end
end

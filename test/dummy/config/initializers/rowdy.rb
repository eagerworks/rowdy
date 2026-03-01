# test/dummy/config/initializers/rowdy.rb

Rails.application.config.to_prepare do
  Rowdy.configure do |config|
    config.processor = lambda do |input_path, upload, &progress|
      (0..100).step(10).each do |i|
        sleep(0.5)
        progress.call(i) if progress
      end

      input_path
    end

    config.schemas = [ ProductImportSchema ]
  end
end

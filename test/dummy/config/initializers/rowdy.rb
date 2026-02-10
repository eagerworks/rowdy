Rowdy.configure do |config|
  config.processor = lambda do |input_path, upload, &progress|
    (0..100).step(10).each do |i|
      sleep(0.5)
      progress.call(i) if progress
    end

    input_path
  end
end

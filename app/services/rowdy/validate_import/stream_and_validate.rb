require "creek"

module Rowdy
  module ValidateImport
    class StreamAndValidate
      extend LightService::Action

      expects :import, :schema, :input_path

      executed do |ctx|
        import = ctx.import
        schema = ctx.schema
        column_mapping = import.column_mapping || {}
        batch_size = Rowdy.configuration.import_batch_size
        broadcast_interval = Rowdy.configuration.progress_broadcast_interval
        estimated_total = [ (import.upload.sheet_dimension.to_f / import.upload.avg_bytes_per_row).round, 1 ].max

        book = Creek::Book.new(ctx.input_path)
        sheet = book.sheets.first
        unique_tracker = UniqueTracker.new

        headers = nil
        total_mapped_rows = 0
        valid_count = 0
        invalid_count = 0
        error_buffer = []

        import.update!(status: :validating)

        sheet.rows.each_with_index do |row, index|
          if index.zero?
            headers = row.values.map(&:to_s)
            next
          end

          total_mapped_rows += 1
          raw_values = row.values

          mapped_row = map_row(headers, raw_values, column_mapping)
          transformed_row = RowTransformer.call(mapped_row, schema)
          row_errors = RowValidator.call(transformed_row, schema, unique_tracker: unique_tracker)

          if row_errors.empty?
            valid_count += 1
          else
            invalid_count += 1
            error_buffer << {
              import_id: import.id,
              row_number: total_mapped_rows + 1,
              row_data: mapped_row,
              column_errors: row_errors,
              created_at: Time.current,
              updated_at: Time.current
            }

            if error_buffer.size >= batch_size
              flush_errors(error_buffer)
              error_buffer.clear
            end
          end

          if (total_mapped_rows % broadcast_interval).zero?
            update_progress(import, estimated_total, valid_count, invalid_count, cap: 99)
          end
        end

        flush_errors(error_buffer) if error_buffer.any?
        update_progress(import, total_mapped_rows, valid_count, invalid_count)

        book.close
      rescue => e
        Rails.logger.error("Import validation failed for Import ID #{import.id}: #{e.message}")
        ctx.fail!("Validation failed: #{e.message}")
      end

      def self.map_row(headers, values, column_mapping)
        mapped = {}

        column_mapping.each do |uploaded_col, schema_col|
          col_index = headers.index(uploaded_col)
          next if col_index.nil?

          mapped[schema_col.to_sym] = values[col_index]
        end

        mapped
      end

      def self.flush_errors(buffer)
        return if buffer.empty?

        ImportError.insert_all(buffer)
      end

      def self.update_progress(import, total_rows, valid_count, invalid_count, cap: nil)
        progress = total_rows.positive? ? ((valid_count + invalid_count).to_f / total_rows * 100).round : 0
        progress = [ progress, cap ].min if cap

        import.update!(
          total_rows: total_rows,
          valid_rows_count: valid_count,
          invalid_rows_count: invalid_count,
          progress: progress
        )
      end

      private_class_method :map_row, :flush_errors, :update_progress
    end
  end
end

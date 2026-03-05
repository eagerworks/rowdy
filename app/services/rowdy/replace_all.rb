module Rowdy
  class ReplaceAll
    CORRECTED_BATCH_SIZE = 5_000

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(import:, column:, find_value:, replace_value:,
                   all_empty: false, case_sensitive: true, exact_match: true)
      @import         = import
      @column         = column
      @find_value     = find_value
      @replace_value  = replace_value
      @all_empty      = all_empty
      @case_sensitive = case_sensitive
      @exact_match    = exact_match
    end

    def call
      corrected_ids   = []
      corrected_count = 0
      schema          = @import.schema

      @import.import_errors.active
        .where(*JsonQueryHelpers.has_key_condition("column_errors", @column))
        .where(*value_filter)
        .find_each(batch_size: 1000) do |import_error|
          updated_row   = import_error.row_data.merge(@column => @replace_value)
          column_errors = RowValidator.call(updated_row.transform_keys(&:to_sym), schema)

          if column_errors.empty?
            corrected_ids   << import_error.id
            corrected_count += 1

            if corrected_ids.size >= CORRECTED_BATCH_SIZE
              flush_corrected(corrected_ids)
              corrected_ids = []
            end
          else
            import_error.update!(row_data: updated_row, column_errors:)
          end
        end

      flush_corrected(corrected_ids) if corrected_ids.any?

      return unless corrected_count > 0

      @import.update_columns(
        invalid_rows_count: @import.invalid_rows_count - corrected_count,
        valid_rows_count:   @import.valid_rows_count   + corrected_count
      )
    end

    private

    def flush_corrected(ids)
      json_sql, *binds = JsonQueryHelpers.json_set_sql("row_data", @column, @replace_value)
      ImportError.where(id: ids).update_all([ "corrected_at = ?, #{json_sql}", Time.current, *binds ])
    end

    def value_filter
      if @all_empty
        JsonQueryHelpers.empty_condition("row_data", @column)
      elsif @case_sensitive && @exact_match
        JsonQueryHelpers.exact_condition("row_data", @column, @find_value)
      elsif @case_sensitive
        JsonQueryHelpers.contains_condition("row_data", @column, @find_value)
      elsif @exact_match
        JsonQueryHelpers.exact_condition("row_data", @column, @find_value, case_sensitive: false)
      else
        JsonQueryHelpers.contains_condition("row_data", @column, @find_value, case_sensitive: false)
      end
    end
  end
end

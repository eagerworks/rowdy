module Rowdy
  class ReplaceAll
    CORRECTED_BATCH_SIZE = 5_000
    ERRORED_BATCH_SIZE = 5_000

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
      errored_updates = []
      corrected_count = 0
      schema          = @import.schema
      now             = Time.current
      unique_tracker  = build_unique_tracker(schema)

      @import.import_rows.errored.active
        .where(*JsonQueryHelpers.has_key_condition("column_errors", @column))
        .where(*value_filter)
        .find_each(batch_size: 1000) do |import_row|
          updated_row   = import_row.row_data.merge(@column => @replace_value)
          column_errors = RowValidator.call(
            updated_row.transform_keys(&:to_sym),
            schema,
            unique_tracker:
          )

          if column_errors.empty?
            corrected_ids   << import_row.id
            corrected_count += 1

            if corrected_ids.size >= CORRECTED_BATCH_SIZE
              flush_corrected(corrected_ids, now)
              corrected_ids = []
            end
          else
            errored_updates << {
              id:            import_row.id,
              import_id:     import_row.import_id,
              row_number:    import_row.row_number,
              row_data:      updated_row,
              column_errors: column_errors,
              created_at:    import_row.created_at,
              updated_at:    now
            }

            if errored_updates.size >= ERRORED_BATCH_SIZE
              flush_errored(errored_updates)
              errored_updates = []
            end
          end
        end

      flush_corrected(corrected_ids, now) if corrected_ids.any?
      flush_errored(errored_updates) if errored_updates.any?

      return unless corrected_count > 0

      @import.update_columns(
        invalid_rows_count: @import.invalid_rows_count - corrected_count,
        valid_rows_count:   @import.valid_rows_count   + corrected_count
      )
    end

    private

    def flush_corrected(ids, now)
      json_sql, *binds = JsonQueryHelpers.json_set_sql("row_data", @column, @replace_value)
      ImportRow.where(id: ids).update_all([ "corrected_at = ?, column_errors = NULL, #{json_sql}", now, *binds ])
    end

    def flush_errored(rows)
      ImportRow.upsert_all(rows, update_only: %i[row_data column_errors])
    end

    def build_unique_tracker(schema)
      tracker        = UniqueTracker.new
      unique_columns = schema.columns.select(&:unique?)
      return tracker if unique_columns.empty?

      batch_subquery = @import.import_rows.errored.active
        .where(*JsonQueryHelpers.has_key_condition("column_errors", @column))
        .where(*value_filter)
        .select(:id)

      @import.import_rows
        .where.not(id: batch_subquery)
        .select(:id, :row_data)
        .find_each(batch_size: 1000) do |row|
          unique_columns.each do |col|
            value = row.row_data[col.name.to_s]
            tracker.add?(col.name, value) unless value.nil?
          end
        end

      tracker
    end

    def value_filter
      return JsonQueryHelpers.empty_condition("row_data", @column) if @all_empty

      method = @exact_match ? :exact_condition : :contains_condition

      JsonQueryHelpers.public_send(
        method,
        "row_data",
        @column,
        @find_value,
        @case_sensitive
      )
    end
  end
end

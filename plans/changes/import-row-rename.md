# Plan: Rename ImportError → ImportRow + Persist All Rows

## Context

To support SQL-based uniqueness validation across ALL rows (valid and invalid),
`rowdy_import_errors` is renamed to `rowdy_import_rows` and the model is renamed
`ImportError` → `ImportRow`. Valid rows are now also persisted with `column_errors: nil`.

---

<step>
<step_n>STEP 1</step_n>
<step_description>
- db/migrate/20260309000000_rename_rowdy_import_errors_to_import_rows.rb (NEW)
</step_description>
</step>

<step>
<step_n>STEP 2</step_n>
<step_description>
- app/models/rowdy/import_row.rb (NEW)
- app/models/rowdy/import_error.rb (DELETED)
</step_description>
</step>

<step>
<step_n>STEP 3</step_n>
<step_description>
- app/models/rowdy/import.rb (has_many :import_rows)
</step_description>
</step>

<step>
<step_n>STEP 4</step_n>
<step_description>
- app/services/rowdy/validate_import/stream_and_validate.rb (buffer ALL rows)
</step_description>
</step>

<step>
<step_n>STEP 5</step_n>
<step_description>
- app/services/rowdy/validate_import/mark_as_preparing.rb
- app/services/rowdy/validate_import/generate_error_report.rb
- app/services/rowdy/column_validators/unique_validator.rb (table name + param rename)
- app/services/rowdy/column_validators/column_validation_pipeline.rb (param rename)
- app/services/rowdy/row_validator.rb (param rename)
- app/services/rowdy/replace_all.rb (import_rows.errored)
</step_description>
</step>

<step>
<step_n>STEP 6</step_n>
<step_description>
- app/controllers/rowdy/imports_controller.rb
- app/controllers/rowdy/imports/validations_controller.rb
</step_description>
</step>

<step>
<step_n>STEP 7</step_n>
<step_description>
- app/queries/rowdy/errored_columns_query.rb
</step_description>
</step>

<step>
<step_n>STEP 8</step_n>
<step_description>
- app/components/rowdy/invalid_row_component.rb
- app/components/rowdy/invalid_row_component.html.erb
- app/components/rowdy/validation_result_component.rb
- app/components/rowdy/validation_result_component.html.erb
</step_description>
</step>

<step>
<step_n>STEP 9</step_n>
<step_description>
- spec/factories/rowdy/import_errors.rb → spec/factories/rowdy/import_rows.rb (RENAMED)
- spec/models/rowdy/import_error_spec.rb → spec/models/rowdy/import_row_spec.rb (RENAMED)
- spec/models/rowdy/import_spec.rb
- spec/services/rowdy/column_validators/unique_validator_spec.rb
- spec/services/rowdy/validate_import/stream_and_validate_spec.rb
- spec/services/rowdy/replace_all_spec.rb
- spec/components/rowdy/invalid_row_component_spec.rb
- spec/requests/rowdy/imports_spec.rb
</step_description>
</step>

<step>
<step_n>STEP 10</step_n>
<step_description>
- test/dummy/db/schema.rb
</step_description>
</step>

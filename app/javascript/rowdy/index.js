import RowdyDropzoneController from "controllers/rowdy/rowdy_dropzone_controller"
import RowdyValidateController from "controllers/rowdy/rowdy_validate_controller"
import RowdyInlineEditController from "controllers/rowdy/rowdy_inline_edit_controller"
import RowdyDirtyFormController from "controllers/rowdy/rowdy_dirty_form_controller"
import RowdyFindReplaceController from "controllers/rowdy/rowdy_find_replace_controller"
import RowdySchemaBuilderController from "controllers/rowdy/rowdy_schema_builder_controller"

export function install(application) {
  application.register("rowdy-dropzone", RowdyDropzoneController)
  application.register("rowdy-validate", RowdyValidateController)
  application.register("rowdy-inline-edit", RowdyInlineEditController)
  application.register("rowdy-dirty-form", RowdyDirtyFormController)
  application.register("rowdy-find-replace", RowdyFindReplaceController)
  application.register("rowdy-schema-builder", RowdySchemaBuilderController)
}

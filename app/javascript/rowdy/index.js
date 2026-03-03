import RowdyDropzoneController from "controllers/rowdy/rowdy_dropzone_controller"
import RowdyValidateController from "controllers/rowdy/rowdy_validate_controller"
import RowdyInlineEditController from "controllers/rowdy/rowdy_inline_edit_controller"
import RowdyDirtyFormController from "controllers/rowdy/rowdy_dirty_form_controller"

export function install(application) {
  application.register("rowdy-dropzone", RowdyDropzoneController)
  application.register("rowdy-validate", RowdyValidateController)
  application.register("rowdy-inline-edit", RowdyInlineEditController)
  application.register("rowdy-dirty-form", RowdyDirtyFormController)
}

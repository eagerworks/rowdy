import RowdyDropzoneController from "controllers/rowdy/rowdy_dropzone_controller"
import RowdyValidateController from "controllers/rowdy/rowdy_validate_controller"

export function install(application) {
  application.register("rowdy-dropzone", RowdyDropzoneController)
  application.register("rowdy-validate", RowdyValidateController)
}

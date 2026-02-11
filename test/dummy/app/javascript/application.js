import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = false
window.Stimulus = application

// Engine controllers (provided by Rowdy via importmap)
import RowdyDropzoneController from "controllers/rowdy/rowdy_dropzone_controller"
application.register("rowdy-dropzone", RowdyDropzoneController)

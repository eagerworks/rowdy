import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = false
window.Stimulus = application

import { install as installRowdy } from "rowdy"
installRowdy(application)

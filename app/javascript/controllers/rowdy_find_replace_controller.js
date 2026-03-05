import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "findInput"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  toggleAllEmpty(event) {
    this.findInputTarget.disabled = event.target.checked
  }
}

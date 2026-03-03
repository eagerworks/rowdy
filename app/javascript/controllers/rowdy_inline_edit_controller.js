import { Controller } from "@hotwired/stimulus"

// Mounted on the <input> itself. The input is always in the DOM (never hidden)
// so it is always submitted with the bulk form. Read/edit appearance is CSS-only.
export default class extends Controller {
  revert(event) {
    if (event.key !== "Escape") return
    this.element.value = this.element.dataset.originalValue
    this.element.blur()
  }
}

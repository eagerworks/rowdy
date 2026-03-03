import { Controller } from "@hotwired/stimulus"

// Warns before pagination discards unsaved edits. Relies on data-original-value
// being present on every editable input (set server-side at render time).
export default class extends Controller {
  static values = { confirm: String }

  get isDirty() {
    return Array.from(this.element.querySelectorAll("[data-original-value]"))
      .some(input => input.value !== input.dataset.originalValue)
  }

  confirmNavigation(event) {
    if (this.isDirty && !confirm(this.confirmValue)) {
      event.preventDefault()
    }
  }
}

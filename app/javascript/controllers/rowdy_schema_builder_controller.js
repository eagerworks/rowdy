import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "columnsContainer", "columnTemplate", "errorContainer"]
  static values = {
    edit: { type: Boolean, default: false },
    initialIndex: { type: Number, default: 0 }
  }

  columnIndex = 0

  connect() {
    this.columnIndex = this.initialIndexValue
    if (this.editValue) {
      this.updateRemoveButtons()
    }
  }

  open() {
    if (this.editValue) {
      this.dialogTarget.showModal()
    } else {
      this.resetForm()
      this.addColumn()
      this.dialogTarget.showModal()
    }
  }

  close() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }

  addColumn() {
    const idx = this.columnIndex++
    const clone = this.columnTemplateTarget.content.cloneNode(true)

    clone.querySelectorAll("[name*='__INDEX__']").forEach(el => {
      el.name = el.name.replace(/__INDEX__/g, idx)
    })

    const row = clone.querySelector(".rowdy-schema-column-row")
    row.dataset.columnIndex = idx

    const typeSelect = row.querySelector("select")
    this.#applyTypeVisibility(row, typeSelect.value)

    this.columnsContainerTarget.appendChild(clone)
    this.updateRemoveButtons()
  }

  removeColumn(event) {
    const row = event.target.closest("[data-column-index]")

    if (row) {
      row.remove()
      this.updateRemoveButtons()
    }
  }

  updateRemoveButtons() {
    const rows = this.columnsContainerTarget.querySelectorAll(".rowdy-schema-column-row")

    rows.forEach(row => {
      const btn = row.querySelector("[data-action*='removeColumn']")
      if (btn) btn.disabled = rows.length <= 1
    })
  }

  toggleTypeFields(event) {
    const row = event.target.closest("[data-column-index]")
    this.#applyTypeVisibility(row, event.target.value)
  }

  #applyTypeVisibility(row, type) {
    row.querySelectorAll("[data-visible-for]").forEach(el => {
      const allowedTypes = el.dataset.visibleFor.split(" ")
      el.style.display = allowedTypes.includes(type) ? "" : "none"
    })
  }

  resetForm() {
    this.formTarget.reset()
    this.columnsContainerTarget.innerHTML = ""
    this.errorContainerTarget.innerHTML = ""
    this.columnIndex = 0
  }
}

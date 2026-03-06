import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "columnsContainer", "columnTemplate", "errorContainer"]

  columnIndex = 0

  open() {
    this.resetForm()
    this.addColumn()
    this.dialogTarget.showModal()
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
    const inclusionGroup = row.querySelector(".rowdy-schema-inclusion-group")
    inclusionGroup.style.display = typeSelect.value === "string" ? "" : "none"

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

  toggleInclusion(event) {
    const row = event.target.closest("[data-column-index]")
    const type = event.target.value
    const inclusionGroup = row.querySelector(".rowdy-schema-inclusion-group")

    inclusionGroup.style.display = type === "string" ? "" : "none"
  }

  resetForm() {
    this.formTarget.reset()
    this.columnsContainerTarget.innerHTML = ""
    this.errorContainerTarget.innerHTML = ""
    this.columnIndex = 0
  }
}

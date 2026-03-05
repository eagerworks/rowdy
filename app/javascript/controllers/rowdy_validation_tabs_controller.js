import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabButton", "tabPanel"]

  connect() {
    this.showTab(0)
  }

  select(event) {
    const index = this.tabButtonTargets.indexOf(event.currentTarget)
    if (index !== -1) this.showTab(index)
  }

  showTab(index) {
    this.tabPanelTargets.forEach((panel, i) => {
      panel.classList.toggle("rowdy-validation-tab-panel--active", i === index)
      panel.hidden = i !== index
    })
    this.tabButtonTargets.forEach((btn, i) => {
      btn.classList.toggle("rowdy-validation-tab--active", i === index)
      btn.setAttribute("aria-selected", i === index)
    })
  }
}

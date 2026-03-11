import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabButton", "tabPanel", "pageLink"]
  static values  = { initialTab: { type: Number, default: 0 } }

  connect() {
    this.showTab(this.initialTabValue)
  }

  select(event) {
    const index = this.tabButtonTargets.indexOf(event.currentTarget)
    if (index === -1) return
    this.showTab(index)
    this.pageLinkTargets.forEach(link => {
      const url = new URL(link.href)
      url.searchParams.set("tab", index)
      link.href = url
    })
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

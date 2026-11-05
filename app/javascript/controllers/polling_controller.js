import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 2000 } }

  connect() {
    this.timer = window.setInterval(() => this.refresh(), this.intervalValue)
  }

  disconnect() {
    window.clearInterval(this.timer)
  }

  async refresh() {
    const response = await fetch(this.urlValue, {
      headers: { "Accept": "text/html", "Turbo-Frame": "import-transactions" }
    })
    if (!response.ok) return

    const html = await response.text()
    const document = new DOMParser().parseFromString(html, "text/html")
    const next = document.querySelector("[data-controller~='polling']")
    if (next) this.element.innerHTML = next.innerHTML
  }
}

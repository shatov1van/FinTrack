import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name"]

  connect() {
    this.input = this.element.querySelector('input[type="file"]')
    this.input?.addEventListener("change", this.updateName)
    this.element.addEventListener("dragover", this.handleDragOver)
    this.element.addEventListener("dragleave", this.handleDragLeave)
    this.element.addEventListener("drop", this.handleDrop)
  }

  disconnect() {
    this.input?.removeEventListener("change", this.updateName)
    this.element.removeEventListener("dragover", this.handleDragOver)
    this.element.removeEventListener("dragleave", this.handleDragLeave)
    this.element.removeEventListener("drop", this.handleDrop)
  }

  updateName = () => {
    const file = this.input?.files?.[0]
    this.nameTarget.textContent = file ? `Выбран файл: ${file.name}` : "Файл не выбран"
  }

  handleDragOver = (event) => {
    event.preventDefault()
    this.element.classList.add("is-dragging")
  }

  handleDragLeave = () => {
    this.element.classList.remove("is-dragging")
  }

  handleDrop = (event) => {
    event.preventDefault()
    this.element.classList.remove("is-dragging")
    if (!this.input || !event.dataTransfer.files.length) return

    this.input.files = event.dataTransfer.files
    this.updateName()
  }
}

// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const applyTheme = () => {
  const isDark = document.documentElement.classList.contains("dark")
  const icon = document.getElementById("theme-icon")
  if (icon) icon.textContent = isDark ? "☾" : "☀"
}

if (localStorage.getItem("theme") === "dark") {
  document.documentElement.classList.add("dark")
}

document.addEventListener("turbo:load", () => {
  const button = document.getElementById("theme-toggle")
  if (!button || button.dataset.themeBound) return

  button.dataset.themeBound = "true"
  button.addEventListener("click", () => {
    document.documentElement.classList.toggle("dark")
    localStorage.setItem(
      "theme",
      document.documentElement.classList.contains("dark") ? "dark" : "light"
    )
    applyTheme()
  })
  applyTheme()
})

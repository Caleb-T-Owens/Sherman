import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "entry", "entryTemplate", "totalDebits", "totalCredits", "difference"]

  connect() {
    this.updateTotals()
  }

  addEntry(event) {
    event.preventDefault()

    const content = this.entryTemplateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.entriesTarget.insertAdjacentHTML("beforeend", content)
    this.updateTotals()
  }

  removeEntry(event) {
    event.preventDefault()

    const entry = event.target.closest('[data-transaction-form-target="entry"]')
    const destroyField = entry.querySelector('input[name*="_destroy"]')

    if (destroyField) {
      // Mark for destruction if persisted
      destroyField.value = "1"
      entry.style.display = "none"
    } else {
      // Remove from DOM if new
      entry.remove()
    }

    this.updateTotals()
  }

  updateTotals() {
    let totalDebits = 0
    let totalCredits = 0

    this.entryTargets.forEach(entry => {
      // Skip hidden entries (marked for destruction)
      if (entry.style.display === "none") return

      const amountField = entry.querySelector('input[name*="[amount]"]')
      const typeField = entry.querySelector('select[name*="[entry_type]"]')

      if (!amountField || !typeField) return

      const amount = parseFloat(amountField.value) || 0
      const type = typeField.value

      if (type === "debit") {
        totalDebits += amount
      } else if (type === "credit") {
        totalCredits += amount
      }
    })

    const difference = totalDebits - totalCredits

    this.totalDebitsTarget.textContent = this.formatCurrency(totalDebits)
    this.totalCreditsTarget.textContent = this.formatCurrency(totalCredits)
    this.differenceTarget.textContent = this.formatCurrency(difference)

    // Highlight difference if not balanced
    if (Math.abs(difference) < 0.01) {
      this.differenceTarget.style.color = "green"
    } else {
      this.differenceTarget.style.color = "red"
    }
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }
}

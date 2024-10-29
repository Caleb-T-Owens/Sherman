import { Injectable, Inject } from '@angular/core'
import { DOCUMENT } from '@angular/common'

@Injectable({
  providedIn: 'root',
})
export class SEOService {
  constructor(@Inject(DOCUMENT) private dom: Document) {}

  updateCanonicalUrl(url: string) {
    const head = this.dom.querySelector('head')
    if (!head) return

    let element = this.dom.querySelector<HTMLLinkElement>(
      `link[rel='canonical']`
    )

    if (!element) {
      element = this.dom.createElement('link') as HTMLLinkElement
      head.appendChild(element)
    }

    element.setAttribute('rel', 'canonical')
    element.setAttribute('href', url)
  }

  clearCanonicalUrl() {
    const head = this.dom.querySelector('head')
    if (!head) return

    const element = this.dom.querySelector<HTMLLinkElement>(
      `link[rel='canonical']`
    )
    if (!element) return

    head.removeChild(element)
  }
}

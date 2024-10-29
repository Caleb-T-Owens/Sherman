import { Component, Inject, OnDestroy } from '@angular/core'
import { RouterLink } from '@angular/router'
import { SEOService } from '../seo.service'

@Component({
  selector: 'cto-home-page',
  standalone: true,
  templateUrl: 'home.component.html',
  imports: [RouterLink],
})
export class HomeComponent implements OnDestroy {
  constructor(@Inject(SEOService) private seoService: SEOService) {
    this.seoService.updateCanonicalUrl('https://cto.je')
  }

  ngOnDestroy(): void {
    this.seoService.clearCanonicalUrl()
  }
}

import { Component } from '@angular/core'
import { RouterLink } from '@angular/router'

@Component({
  selector: 'cto-home-page',
  standalone: true,
  templateUrl: 'home.component.html',
  imports: [RouterLink],
})
export class HomeComponent {}

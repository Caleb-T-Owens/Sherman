import { Component } from '@angular/core'
import { RouterLink } from '@angular/router'

@Component({
  standalone: true,
  templateUrl: 'phrases.component.html',
  imports: [RouterLink],
})
export class PhrasesComponent {}

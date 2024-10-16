import { Component } from '@angular/core'
import { RouterOutlet } from '@angular/router'
import { NavigationComponent } from './navigation.component'
import { FontSelectorComponent } from '../font-selector/font-selector.component'

@Component({
  selector: 'cto-main-layout',
  standalone: true,
  imports: [RouterOutlet, NavigationComponent, FontSelectorComponent],
  template: `
    <h1 class="title">Caleb Owens' Website</h1>
    <cto-font-selector></cto-font-selector>
    <cto-main-navigation></cto-main-navigation>
    <router-outlet></router-outlet>
  `,
})
export class MainLayoutComponent {}

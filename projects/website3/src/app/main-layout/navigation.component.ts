import { Component } from '@angular/core'
import { RouterLink } from '@angular/router'

@Component({
  selector: 'cto-main-navigation',
  standalone: true,
  imports: [RouterLink],
  template: `
    <header class="page-header">
      <nav>
        <h2>Main</h2>
        <ul>
          <li><a routerLink="/">Home</a></li>
          <li><a routerLink="/phrases">Phrases</a></li>
          <li><a href="https://notes.cto.je">Notes</a></li>
        </ul>
      </nav>
      <nav>
        <h2>Tech</h2>
        <ul>
          <li><a routerLink="/projects">Projects</a></li>
        </ul>
      </nav>
      <nav>
        <h2>External</h2>
        <ul>
          <li>
            <a
              href="https://github.com/Caleb-T-Owens/Sherman/tree/main/projects/website3"
              >Website source code</a
            >
          </li>
        </ul>
      </nav>
    </header>
  `,
})
export class NavigationComponent {}

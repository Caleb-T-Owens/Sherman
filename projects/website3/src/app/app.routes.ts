import { Routes } from '@angular/router'
import { HomeComponent } from './home/home.component'
import { MainLayoutComponent } from './main-layout/main-layout.component'
import { MagpiesNestComponent } from './phrases/magpies-nest/magpies-nest.component'
import { PhrasesComponent } from './phrases/phrases.component'
import { ProjectsComponent } from './projects/projects.component'
import { DevlogComponent } from './devlog/devlog.component'

export const routes: Routes = [
  {
    path: '',
    component: MainLayoutComponent,
    children: [
      { path: '', component: HomeComponent },
      {
        path: 'phrases',
        children: [
          { path: '', component: PhrasesComponent },
          { path: 'magpies-nest', component: MagpiesNestComponent },
        ],
      },
      {
        path: 'projects',
        children: [{ path: '', component: ProjectsComponent }],
      },
      {
        path: 'devlog',
        children: [{ path: '', component: DevlogComponent }],
      },
    ],
  },
]

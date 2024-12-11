import { AsyncPipe } from '@angular/common'
import { HttpClient } from '@angular/common/http'
import { Component } from '@angular/core'
import { combineLatest, map, Observable } from 'rxjs'

type PocketBase = {
  collectionId: string
  collectionName: string
  created: string
  updated: string
  id: string
}

type ApiProject = PocketBase & {
  name: string
  referenceUrl: string
}

type ApiDevlog = PocketBase & {
  entry: string
  referenceUrl: string
  occuredAt: string
  projectId: string
}

type Project = {
  name: string
  referenceUrl?: string
}

function apiToProject(apiProject: ApiProject): Project {
  return {
    name: apiProject.name,
    referenceUrl: apiProject.referenceUrl || undefined,
  }
}

type Devlog = {
  entry: string
  referenceUrl?: string
  occuredAt: Date
  project: Project
}
function apiToDevlog(
  apiDevlog: ApiDevlog,
  projectsById: Map<string, Project>
): Devlog {
  return {
    entry: apiDevlog.entry,
    referenceUrl: apiDevlog.referenceUrl || undefined,
    occuredAt: new Date(apiDevlog.occuredAt),
    project: projectsById.get(apiDevlog.projectId)!,
  }
}

type CollectionResponse<T extends PocketBase> = {
  page: number
  pageSize: number
  totalItems: number
  totalPages: number
  items: T[]
}

@Component({
  standalone: true,
  templateUrl: 'devlog.component.html',
  imports: [AsyncPipe],
})
export class DevlogComponent {
  devlogs: Observable<Devlog[]>

  constructor(httpClient: HttpClient) {
    const projectsById = httpClient
      .get<CollectionResponse<ApiProject>>(
        'https://serverless.cto.je/api/collections/projects/records',
        {
          params: {
            perPage: 999,
          },
        }
      )
      .pipe(
        map((response) => {
          const entries = response.items.map(
            (item) => [item.id, apiToProject(item)] as [string, Project]
          )

          return new Map<string, Project>(entries)
        })
      )

    const apiDevlogs = httpClient.get<CollectionResponse<ApiDevlog>>(
      'https://serverless.cto.je/api/collections/devlogs/records',
      {
        params: {
          perPage: 999,
        },
      }
    )

    this.devlogs = combineLatest([projectsById, apiDevlogs]).pipe(
      map(([projectsById, apiDevlogs]) => {
        const devlog = apiDevlogs.items.map((item) =>
          apiToDevlog(item, projectsById)
        )

        devlog.sort((a, b) => b.occuredAt.getTime() - a.occuredAt.getTime())

        return devlog
      })
    )
  }
}

import { Site } from "@/types"

type Props = {
    sites: Site[];
}

export default function SitesList({ sites }: Props) {
    return (
        <ul>
            {sites.map((site) => (
                <li key={site.id}>
                <p style={{ marginBottom: "2px" }}>{site.title} - <a href={site.url}>{site.url}</a></p>
                <small>{site.description}</small>
                </li>
            ))}
        </ul>
    )
}
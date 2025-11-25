import { Site } from "@/types";
import { useForm } from "@inertiajs/react";

type Props = {
  sites: Site[];
};

export default function SitesList({ sites }: Props) {
  return (
    <ul>
      {sites.map((site) => (
        <li key={site.id}>
          <p style={{ marginBottom: "2px" }}>
            <DeleteSite siteId={site.id} /> {site.title} -{" "}
            <a href={site.url}>{site.url}</a>
          </p>
          <small>{site.description}</small>
        </li>
      ))}
    </ul>
  );
}

function DeleteSite({ siteId }: { siteId: number }) {
  const { delete: formDelete } = useForm();

  function deleteSite() {
    formDelete(`/sites/${siteId}`);
  }

  return <button onClick={deleteSite}>X</button>;
}

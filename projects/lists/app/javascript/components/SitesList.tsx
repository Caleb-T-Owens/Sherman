import { Site } from "@/types";
import { useForm } from "@inertiajs/react";
import Fuse from "fuse.js";
import { useEffect, useState } from "react";

type Props = {
  sites: Site[];
  searchTerm?: string;
};

export default function SitesList({ sites, searchTerm }: Props) {
  const [cursor, setCursor] = useState(0);
  const sortedSites = sortSites(sites, searchTerm);

  useEffect(() => {
    setCursor(0);
  }, [searchTerm, sites]);

  useEffect(() => {
    function visitSite() {
      const toVisit = sortedSites[cursor]!.url;
      window.location.href = toVisit;
    }

    function handle(e: KeyboardEvent) {
      if (e.ctrlKey && e.key === "Enter") {
        e.preventDefault();
        visitSite();
        return;
      }

      if (e.ctrlKey && e.key === "j") {
        e.preventDefault();
        if (cursor + 1 < sortedSites.length) {
          setCursor(cursor + 1);
        }
        return;
      }

      if (e.ctrlKey && e.key === "k") {
        e.preventDefault();
        if (cursor - 1 >= 0) {
          setCursor(cursor - 1);
        }
        return;
      }
    }

    document.addEventListener("keydown", handle);

    // Maintain cursor bounds
    if (cursor >= sortedSites.length) {
      setCursor(sortedSites.length - 1);
    }
    if (cursor <= 0) {
      setCursor(0);
    }

    return () => {
      document.removeEventListener("keydown", handle);
    };
  }, [sortedSites, cursor]);

  return (
    <ul>
      {sortedSites.map((site, idx) => (
        <li
          key={site.id}
          className={idx === cursor ? "site-cursor-focus" : undefined}
        >
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

function sortSites(sites: Site[], searchTerm?: string): Site[] {
  if (searchTerm) {
    const fuse = new Fuse(sites, {
      includeScore: true,
      keys: [
        {
          name: "title",
          weight: 3,
        },
        {
          name: "url",
          weight: 2,
        },
        {
          name: "description",
          weight: 1,
        },
      ],
    });

    const output = fuse.search(searchTerm);
    return output.map((o) => o.item);
  } else {
    const out = [...sites];
    out.sort((a, b) => {
      return a.url.toLowerCase().localeCompare(b.url.toLowerCase());
    });
    return out;
  }
}

import Layout from "@/components/Layout";
import SiteForm from "@/components/SiteForm";
import SitesList from "@/components/SitesList";
import { Site } from "@/types";
import { useEffect, useRef, useState } from "react";

interface MyProps {
  current_user: {
    id: number;
    email: string;
  };
  sites: Site[];
}

function AddSiteDialog() {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [modalOpen, setModalOpen] = useState(false);

  useEffect(() => {
    if (modalOpen) {
      dialogRef.current?.showModal();
    } else {
      dialogRef.current?.close();
    }
  }, [modalOpen, dialogRef.current]);

  useEffect(() => {
    function handler(e: KeyboardEvent) {
      if (e.ctrlKey && e.key === "n") {
        setModalOpen(true);
      }
    }

    document.addEventListener("keydown", handler);

    return () => {
      document.removeEventListener("keydown", handler);
    };
  }, []);

  return (
    <>
      <button type="button" onClick={() => setModalOpen(true)}>
        Add New Site (ctrl + n)
      </button>

      <dialog ref={dialogRef}>
        {modalOpen ? (
          <>
            <h2>Add a Site</h2>
            <SiteForm
              onSuccess={() => setModalOpen(false)}
              onCancel={() => setModalOpen(false)}
              operation={{ kind: "create" }}
            />
          </>
        ) : undefined}
      </dialog>
    </>
  );
}

function My({ sites }: MyProps) {
  const [term, setTerm] = useState("");

  function searchGoogle() {
    window.location.href = `https://google.com/search?q=${encodeURIComponent(term)}`;
  }

  function searchWikipedia() {
    window.location.href = `https://en.wikipedia.org/w/index.php?search=${encodeURIComponent(term)}`;
  }

  useEffect(() => {
    function handle(e: KeyboardEvent) {
      if (e.ctrlKey && e.key === "g") {
        searchGoogle();
        e.preventDefault();
        return;
      }

      if (e.ctrlKey && e.key === "w") {
        searchWikipedia();
        e.preventDefault();
        return;
      }
    }

    document.addEventListener("keydown", handle);

    return () => document.removeEventListener("keydown", handle);
  }, [term]);

  return (
    <>
      <section>
        <h2>Your Sites</h2>
        <input
          autoFocus
          type="text"
          value={term}
          onInput={(e) => {
            setTerm(e.currentTarget.value);
          }}
          placeholder="Search sites"
        ></input>
        <button onClick={searchGoogle}>Search Google (ctrl + g)</button>
        <button onClick={searchWikipedia}>Search Wikipedia (ctrl + w)</button>
        <br />
        <AddSiteDialog />

        {sites.length === 0 ? (
          <p>No sites yet.</p>
        ) : (
          <SitesList sites={sites} searchTerm={term} />
        )}
      </section>
    </>
  );
}

My.layout = (page: React.ReactElement<MyProps>) => <Layout children={page} />;

export default My;

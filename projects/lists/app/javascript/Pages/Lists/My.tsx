import Layout from "@/components/Layout";
import SiteForm from "@/components/SiteForm";
import SitesList from "@/components/SitesList";
import { Site } from "@/types";
import { useEffect, useRef } from "react";

interface MyProps {
  current_user: {
    id: number;
    email: string;
  };
  sites: Site[];
}

function AddSiteDialog() {
  const dialogRef = useRef<HTMLDialogElement>(null);

  const openDialog = () => {
    dialogRef.current?.showModal();
  };

  const closeDialog = () => {
    dialogRef.current?.close();
  };

  useEffect(() => {
    function handler(e: KeyboardEvent) {
      if (e.ctrlKey && e.key === "n") {
        openDialog();
      }
    }

    document.addEventListener("keypress", handler);

    return () => {
      document.removeEventListener("keypress", handler);
    };
  }, []);

  return (
    <>
      <button type="button" onClick={openDialog}>
        Add New Site (ctrl + n)
      </button>

      <dialog ref={dialogRef}>
        <h2>Add a Site</h2>
        <SiteForm onSuccess={closeDialog} onCancel={closeDialog} />
      </dialog>
    </>
  );
}

function My({ sites }: MyProps) {
  return (
    <>
      <section>
        <h2>Your Sites</h2>
        <AddSiteDialog />

        {sites.length === 0 ? (
          <p>No sites yet.</p>
        ) : (
          <SitesList sites={sites} />
        )}
      </section>
    </>
  );
}

My.layout = (page: React.ReactElement<MyProps>) => <Layout children={page} />;

export default My;

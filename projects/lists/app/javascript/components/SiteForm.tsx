import { useForm } from "@inertiajs/react";
import { useEffect, useRef, useState } from "react";
import { fetchMetadata } from "@/api/metadata";

interface SiteFormProps {
  onSuccess: () => void;
  onCancel: () => void;
}

export default function SiteForm({ onSuccess, onCancel }: SiteFormProps) {
  const { data, setData, post, processing, reset } = useForm({
    url: "",
    title: "",
    description: "",
  });

  const formRef = useRef<HTMLFormElement>(null);
  const [fetching, setFetching] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post("/sites", {
      onSuccess: () => {
        reset();
        onSuccess();
      },
    });
  };

  const handleCancel = () => {
    reset();
    onCancel();
  };

  const handleFetchMetadata = async () => {
    if (!data.url) {
      return;
    }

    setFetching(true);
    try {
      const result = await fetchMetadata(data.url);

      if ("error" in result) {
        alert(`Failed to fetch metadata: ${result.error}`);
      } else {
        if (result.title) {
          setData("title", result.title);
        }
        if (result.description) {
          setData("description", result.description);
        }
      }
    } catch (error) {
      alert(`Failed to fetch metadata: ${error}`);
    } finally {
      setFetching(false);
    }
  };

  useEffect(() => {
    function handler(e: KeyboardEvent) {
      if (e.ctrlKey && e.key === "s") {
        e.preventDefault();
        e.stopPropagation();
        formRef.current?.requestSubmit();
        return;
      }

      if (e.ctrlKey && e.key === "c") {
        e.preventDefault();
        e.stopPropagation();
        handleCancel();
        return;
      }

      if (e.ctrlKey && e.key === "m") {
        e.preventDefault();
        e.stopPropagation();
        handleFetchMetadata();
        return;
      }
    }

    document.addEventListener("keydown", handler);

    return () => {
      document.removeEventListener("keydown", handler);
    };
  }, [formRef.current, data, post]);

  return (
    <form ref={formRef} onSubmit={handleSubmit}>
      <div>
        <label htmlFor="url">URL</label>
        <input
          type="url"
          id="url"
          value={data.url}
          onChange={(e) => setData("url", e.target.value)}
          required
        />
        <button
          type="button"
          onClick={handleFetchMetadata}
          disabled={!data.url || fetching}
        >
          {fetching ? "Fetching..." : "Auto-fill (ctrl+m)"}
        </button>
      </div>

      <div>
        <label htmlFor="title">Title</label>
        <input
          type="text"
          id="title"
          value={data.title}
          onChange={(e) => setData("title", e.target.value)}
          required
        />
      </div>

      <div>
        <label htmlFor="description">Description</label>
        <textarea
          id="description"
          value={data.description}
          onChange={(e) => setData("description", e.target.value)}
        />
      </div>

      <div>
        <button type="submit" disabled={processing}>
          Add Site (ctrl + s)
        </button>
        <button type="button" onClick={handleCancel}>
          Cancel (ctrl + c)
        </button>
      </div>
    </form>
  );
}

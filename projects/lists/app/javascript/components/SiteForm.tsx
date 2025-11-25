import { useForm } from "@inertiajs/react";
import { useEffect, useRef } from "react";

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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post("/list/sites", {
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

  useEffect(() => {
    function handler(e: KeyboardEvent) {
      console.log(e.ctrlKey, e.key);
      if (e.ctrlKey && e.key === "s") {
        formRef.current?.submit();
      }

      if (e.ctrlKey && e.key === "c") {
        handleCancel();
      }
    }

    document.addEventListener("keypress", handler);

    return () => {
      document.removeEventListener("keypress", handler);
    };
  }, []);

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="url">URL</label>
        <input
          type="url"
          id="url"
          value={data.url}
          onChange={(e) => setData("url", e.target.value)}
          required
        />
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

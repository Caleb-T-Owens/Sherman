import { useForm } from "@inertiajs/react";

export default function SiteForm() {
  const { data, setData, post, processing, reset } = useForm({
    url: "",
    title: "",
    description: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post("/list/sites", {
      onSuccess: () => reset(),
    });
  };

  return (
    <section>
      <h2>Add a Site</h2>
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

        <button type="submit" disabled={processing}>
          Add Site
        </button>
      </form>
    </section>
  );
}

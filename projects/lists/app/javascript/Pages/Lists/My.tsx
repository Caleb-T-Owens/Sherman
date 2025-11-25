import { router } from "@inertiajs/react";
import SiteForm from "~/components/SiteForm";

interface Site {
  id: number;
  url: string;
  title: string;
  description: string;
  created_at: string;
}

interface MyProps {
  app_name: string;
  current_user?: {
    id: number;
    email: string;
  };
  sites: Site[];
}

export default function My({ app_name, current_user, sites }: MyProps) {
  const handleLogout = () => {
    router.delete("/logout");
  };

  return (
    <main>
      <header>
        <h1>Welcome to {app_name}!</h1>
        <nav>
          {current_user ? (
            <>
              <span>Logged in as: {current_user.email}</span>
              <button onClick={handleLogout}>Logout</button>
            </>
          ) : (
            <>
              <a href="/login">Login</a>
              <a href="/register">Register</a>
            </>
          )}
        </nav>
      </header>

      <SiteForm />

      <section>
        <h2>Your Sites</h2>
        {sites.length === 0 ? (
          <p>No sites yet.</p>
        ) : (
          <ul>
            {sites.map((site) => (
              <li key={site.id}>
                <h3>{site.title}</h3>
                <a href={site.url}>{site.url}</a>
                <p>{site.description}</p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}

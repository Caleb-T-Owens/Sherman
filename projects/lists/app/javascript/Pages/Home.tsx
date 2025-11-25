import { router } from "@inertiajs/react";

interface HomeProps {
  app_name: string;
  current_user?: {
    id: number;
    email: string;
  };
}

export default function Home({ app_name, current_user }: HomeProps) {
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
      <p>Inertia.js with React and TypeScript is working!</p>
    </main>
  );
}

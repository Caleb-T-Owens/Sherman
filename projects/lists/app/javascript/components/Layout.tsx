import { router, usePage } from "@inertiajs/react";
import { ReactNode } from "react";

interface LayoutProps {
  children: ReactNode;
}

interface PageProps {
  current_user?: {
    id: number;
    email: string;
    admin: boolean;
  };
  [key: string]: unknown;
}

export default function Layout({ children }: LayoutProps) {
  const { current_user } = usePage<PageProps>().props;

  const handleLogout = () => {
    router.delete("/logout");
  };

  return (
    <>
      <h1 className="title">Lists</h1>
      <header className="page-header">
        <nav>
          <h2>Main</h2>
          <ul>
            <li>
              <a href="/">Home</a>
            </li>
            {current_user && (
              <li>
                <a href="/list/my">My List</a>
              </li>
            )}
            {current_user?.admin && (
              <li>
                <a href="/admin">Admin</a>
              </li>
            )}
          </ul>
        </nav>
        <nav>
          <h2>Account</h2>
          <ul>
            {current_user ? (
              <>
                <li>
                  <span>Logged in as: {current_user.email}</span>
                </li>
                <li>
                  <button onClick={handleLogout}>Logout</button>
                </li>
              </>
            ) : (
              <>
                <li>
                  <a href="/login">Login</a>
                </li>
                <li>
                  <a href="/register">Register</a>
                </li>
              </>
            )}
          </ul>
        </nav>
      </header>
      <main>{children}</main>
    </>
  );
}

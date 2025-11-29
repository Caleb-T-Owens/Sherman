import { Link, router, usePage } from "@inertiajs/react";
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
      <header className="page-header">
        <nav>
          <h2>Main</h2>
          <ul>
            <li>
              <Link href="/">Home</Link>
            </li>
            {current_user && (
              <li>
                <Link href="/list/my">My List</Link>
              </li>
            )}
            {current_user?.admin && (
              <li>
                <Link href="/admin">Admin</Link>
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
                  <Link href="/login">Login</Link>
                </li>
                <li>
                  <Link href="/register">Register</Link>
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

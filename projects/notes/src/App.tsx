import { createBrowserRouter, RouterProvider } from 'react-router';
import './App.css';
import { Root } from './pages/Root';

const router = createBrowserRouter([
  {
    path: '/',
    Component: Root
  }
]);

function Layout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <main>{children}</main>
    </>
  );
}

function App() {
  return (
    <Layout>
      <RouterProvider router={router} />
    </Layout>
  );
}

export default App;

import Layout from "@/components/Layout";

interface HomeProps {
  current_user?: {
    id: number;
    email: string;
  };
}

function Home({ current_user }: HomeProps) {
  return (
    <>
      {current_user && <p>Inertia.js with React and TypeScript is working!</p>}
    </>
  );
}

Home.layout = (page: React.ReactElement<HomeProps>) => (
  <Layout children={page} />
);

export default Home;

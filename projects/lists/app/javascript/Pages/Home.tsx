interface HomeProps {
  app_name: string;
}

export default function Home({ app_name }: HomeProps) {
  return (
    <div>
      <h1>Welcome to {app_name}!</h1>
      <p>Inertia.js with React and TypeScript is working!</p>
    </div>
  );
}

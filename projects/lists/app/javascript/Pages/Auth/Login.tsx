import { useForm } from "@inertiajs/react";

interface LoginProps {
  errors?: {
    email?: string;
  };
}

export default function Login({ errors }: LoginProps) {
  const { data, setData, post, processing } = useForm({
    email: "",
    password: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post("/login");
  };

  return (
    <main>
      <h1>Login</h1>

      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={data.email}
            onChange={(e) => setData("email", e.target.value)}
            required
          />
          {errors?.email && <p role="alert">{errors.email}</p>}
        </div>

        <div>
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={data.password}
            onChange={(e) => setData("password", e.target.value)}
            required
          />
        </div>

        <button type="submit" disabled={processing}>
          {processing ? "Logging in..." : "Login"}
        </button>
      </form>

      <p>
        Don't have an account? <a href="/register">Register</a>
      </p>
    </main>
  );
}

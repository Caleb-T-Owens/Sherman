import { useForm } from "@inertiajs/react";

interface RegisterProps {
  errors?: {
    email?: string[];
    password?: string[];
    password_confirmation?: string[];
  };
}

export default function Register({ errors }: RegisterProps) {
  const { data, setData, post, processing } = useForm({
    email: "",
    password: "",
    password_confirmation: "",
  });

  return (
    <main>
      <h1>Register</h1>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          post("/register");
        }}
      >
        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            value={data.email}
            onChange={(e) => setData("email", e.target.value)}
            required
          />
          {errors?.email && <p role="alert">{errors.email.join(", ")}</p>}
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
          {errors?.password && <p role="alert">{errors.password.join(", ")}</p>}
        </div>

        <div>
          <label htmlFor="password_confirmation">Confirm Password</label>
          <input
            id="password_confirmation"
            type="password"
            value={data.password_confirmation}
            onChange={(e) => setData("password_confirmation", e.target.value)}
            required
          />
          {errors?.password_confirmation && (
            <p role="alert">{errors.password_confirmation.join(", ")}</p>
          )}
        </div>

        <button type="submit" disabled={processing}>
          {processing ? "Creating account..." : "Register"}
        </button>
      </form>

      <p>
        Already have an account? <a href="/login">Login</a>
      </p>
    </main>
  );
}

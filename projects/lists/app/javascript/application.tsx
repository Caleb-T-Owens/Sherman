import { createRoot } from "react-dom/client";
import { createInertiaApp, router } from "@inertiajs/react";
import { pages } from "./pages";

createInertiaApp({
  resolve: (name) => {
    const page = pages[name];
    if (!page) {
      throw new Error(
        `Page component "${name}" not found. Available pages: ${Object.keys(pages).join(", ")}`
      );
    }
    return page;
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />);
  },
});

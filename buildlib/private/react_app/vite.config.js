// vite.config.js
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ command }) => {
  const base = {
    plugins: [react()],
  };

  if (command !== "serve") {
    return base;
  }

  // Tweak config for dev server (inside docker container).
  return {
    // Use global tmp dir: The directory with the source files is not writeable.
    cacheDir: "/tmp/.vite",
    // Run on port 80 so we do not need to change the proxy config from nginx.
    server: {
      port: 80,
      strictPort: true,
    },
  };
});

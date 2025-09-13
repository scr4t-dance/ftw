import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig, loadEnv } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  console.log("API BASE URL:", env.API_BASE_URL);

  return {
    plugins: [tailwindcss(), reactRouter(), tsconfigPaths()],
    server: {
      proxy: {
        "/api": {
          target: env.API_BASE_URL,
          changeOrigin: true,
        },
      },
    },
  };
});

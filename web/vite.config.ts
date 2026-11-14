import { fileURLToPath, URL } from "url";

import { defineConfig } from "vite";

import tailwindcss from "@tailwindcss/vite";

import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  server: {
    fs: {
      allow: [fileURLToPath(new URL("..", import.meta.url))],
    },
  },
  build: {
    outDir: "./dist",
    emptyOutDir: true,
  },
  base: "./",
});
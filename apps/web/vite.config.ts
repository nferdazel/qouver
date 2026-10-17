import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

const apiTarget = process.env.QOUVER_API_TARGET ?? 'http://127.0.0.1:8091';
const proxy = {
  '/api': { target: apiTarget, changeOrigin: false },
  '/healthz': { target: apiTarget, changeOrigin: false },
};

export default defineConfig({
  plugins: [sveltekit()],
  server: {
    port: 3000,
    proxy,
  },
  preview: {
    port: 3000,
    proxy,
  },
});

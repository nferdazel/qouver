import adapter from '@sveltejs/adapter-static';
import { sveltekit } from '@sveltejs/kit/vite';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import { defineConfig } from 'vite';

const apiTarget = process.env.QOUVER_API_TARGET ?? 'http://127.0.0.1:8091';
const proxy = {
  '/api': { target: apiTarget, changeOrigin: false },
  '/healthz': { target: apiTarget, changeOrigin: false },
};

export default defineConfig({
  plugins: [
    // SvelteKit 3 reads its config from here; svelte.config.js is no longer loaded.
    sveltekit({
      preprocess: vitePreprocess(),
      adapter: adapter({
        pages: 'build',
        assets: 'build',
        // Not 404.html: this route is prerendered as a real page, and
        // adapter-static would overwrite it with the SPA shell. nginx answers
        // unknown paths from 404.html with status 404 (see nginx.conf), so the
        // shell only exists for a client-side route that misses.
        fallback: 'spa-fallback.html',
        precompress: false,
        strict: true,
      }),
      prerender: {
        entries: [
          '*',
          '/projects/skyward',
          '/projects/majadu',
          '/projects/sds',
          '/projects/mdef',
          '/journal/authoritative-go-simulations',
          '/journal/zero-js-static-jaspr',
          '/journal/systems-prospector-manifesto',
        ],
      },
      alias: {
        // SvelteKit 3 dropped `$lib`; keep the name so the existing imports stay put.
        $lib: 'src/lib',
      },
    }),
  ],
  server: {
    port: 3000,
    proxy,
  },
  preview: {
    port: 3000,
    proxy,
  },
});

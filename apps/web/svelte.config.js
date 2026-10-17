import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter({
      pages: 'build',
      assets: 'build',
      fallback: '404.html',
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
  },
};

export default config;

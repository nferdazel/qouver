<script lang="ts">
  import { page } from '$app/state';
  import QMark from '$lib/components/QMark.svelte';
  import {
    siteName,
    contactEmail,
    githubOrgUrl,
    githubMaintainerUrl,
  } from '$lib/site.js';

  let { children } = $props();

  function isActive(path: string): boolean {
    const current = page.url.pathname;
    return current === path || (path !== '/' && current.startsWith(`${path}/`));
  }
</script>

<a class="skip-link" href="#main">Skip to content</a>

<header class="site-header">
  <div class="container site-header__inner">
    <a href="/" class="brand" aria-label="Qouver, home">
      <QMark size="30" class="brand__mark" accentDot={true} />
      <span class="brand__word">Qouver</span>
    </a>
    <nav class="nav" aria-label="Primary">
      <a href="/projects" class="nav__link {isActive('/projects') ? 'nav__link--active' : ''}">Projects</a>
      <a href="/journal" class="nav__link {isActive('/journal') ? 'nav__link--active' : ''}">Journal</a>
      <a href="/about" class="nav__link {isActive('/about') ? 'nav__link--active' : ''}">About</a>
      <a href="/contact" class="nav__link {isActive('/contact') ? 'nav__link--active' : ''}">Contact</a>
    </nav>
  </div>
</header>

<main id="main">
  {@render children()}
</main>

<footer class="site-footer">
  <div class="container">
    <div class="site-footer__top">
      <div>
        <a href="/" class="site-footer__brand" aria-label="Qouver, home">
          <QMark size="28" class="brand__mark" accentDot={true} />
          <span class="brand__word">{siteName}</span>
        </a>
        <p class="footer__tagline">
          Built from what others leave behind. A home for systems and ideas.
        </p>
      </div>
      <div class="site-footer__nav">
        <div class="footer__col">
          <h4>Index</h4>
          <ul>
            <li><a href="/projects">Projects</a></li>
            <li><a href="/journal">Journal</a></li>
            <li><a href="/about">About</a></li>
            <li><a href="/contact">Contact</a></li>
          </ul>
        </div>
        <div class="footer__col">
          <h4>Contact</h4>
          <ul>
            <li><a href="mailto:{contactEmail}">{contactEmail}</a></li>
            <li>
              <a href={githubOrgUrl} target="_blank" rel="noopener">
                github.com/qouver
              </a>
            </li>
            <li>
              <a href={githubMaintainerUrl} target="_blank" rel="noopener">
                github.com/nferdazel
              </a>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <div class="site-footer__bottom">
      <span>© 2026 Qouver</span>
      <span>Set in Fraunces & Archivo · Built with SvelteKit & Nim</span>
      <span>qouver.com</span>
    </div>
  </div>
</footer>

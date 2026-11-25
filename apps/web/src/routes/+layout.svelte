<script lang="ts">
  import { page } from '$app/state';

  let { children } = $props();

  const links = [
    { href: '/projects', label: 'Projects' },
    { href: '/journal', label: 'Journal' },
    { href: '/about', label: 'About' },
    { href: '/contact', label: 'Contact' },
  ];

  function isActive(path: string): boolean {
    const current = page.url.pathname;
    return current === path || current.startsWith(`${path}/`);
  }
</script>

<a class="skip-link" href="#main">Skip to content</a>

<header class="site-header topbar">
  <div class="wrap topbar__in">
    <a href="/" class="brand" aria-label="Qouver, home">
      <span class="brand__dot" aria-hidden="true"></span>
      <b>Qouver</b>
    </a>
    <nav class="nav" aria-label="Primary">
      {#each links as link}
        <a href={link.href} aria-current={isActive(link.href) ? 'page' : undefined}>
          {link.label}
        </a>
      {/each}
    </nav>
  </div>
</header>

<main id="main">
  {@render children()}
</main>

<footer class="site-footer foot">
  <div class="wrap foot__in">
    <span>Qouver / qouver.com</span>
    <span>Built from what others leave behind</span>
    <a href="#main">Top</a>
  </div>
</footer>

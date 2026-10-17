<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectCard from '$lib/components/ProjectCard.svelte';
  import { projects } from '$lib/data/projects.js';
  import {
    siteName,
    siteTagline,
    siteDescription,
    siteUrl,
    contactEmail,
  } from '$lib/site.js';

  const schemaJson = JSON.stringify([
    {
      '@context': 'https://schema.org',
      '@type': 'Organization',
      name: 'Qouver',
      url: siteUrl,
      logo: `${siteUrl}/assets/q-mark.svg`,
      email: contactEmail,
      description: siteDescription,
      sameAs: [
        'https://github.com/qouver',
        'https://github.com/nferdazel',
      ],
    },
    {
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      name: 'Qouver',
      url: siteUrl,
      description:
        'A home for systems and ideas. Find value. Build systems. Share knowledge.',
    },
  ]);
</script>

<SeoHead
  title="{siteName} · {siteTagline}"
  description={siteDescription}
  path="/"
/>

<svelte:head>
  {@html `<script type="application/ld+json">${schemaJson}</script>`}
</svelte:head>

<!-- Hero Section -->
<section class="hero container">
  <div class="hero-inner">
    <h1 class="display hero__display">
      Built from what others <em>leave behind.</em>
    </h1>
    <p class="lead hero__lead">{siteDescription}</p>
  </div>
</section>

<!-- Philosophy / Approach Strip -->
<section class="strip section--tight">
  <div class="container strip__grid">
    <div class="strip__item">
      <span class="strip__num">01</span>
      <h3>Find value in plain sight.</h3>
      <p>
        Valuable things often sit unindexed or overlooked: the gap in a community, the pattern in a dataset, the tool nobody bothered to build.
      </p>
    </div>
    <div class="strip__item">
      <span class="strip__num">02</span>
      <h3>Build real production systems.</h3>
      <p>
        Not prototypes. Not pitch decks. Software running in production, handling real workload, and earning its place.
      </p>
    </div>
    <div class="strip__item">
      <span class="strip__num">03</span>
      <h3>Document every lesson.</h3>
      <p>
        What is built gets documented. Architecture post-mortems and open technical essays mean the next problem starts with context.
      </p>
    </div>
  </div>
</section>

<!-- Production Systems Section -->
<section class="section container">
  <div class="section-head">
    <h2 class="h2">Production Systems</h2>
    <p class="section-head__subtitle">
      Active software systems built and operated by Qouver.
    </p>
  </div>
  <div class="projects-grid">
    {#each projects as project}
      <ProjectCard {project} />
    {/each}
  </div>
  <div class="mt-2">
    <a href="/projects" class="btn btn--secondary">All Systems</a>
  </div>
</section>

<!-- Operational Manifesto Section -->
<section class="manifesto section">
  <div class="container">
    <p class="manifesto__quote">
      Find what others walk past. <em>Build something useful from it.</em> Leave notes for whoever comes next.
    </p>
    <div class="manifesto__row">
      <span class="manifesto__lbl">Operational Manifesto</span>
      <a href="/about" class="link-action link-action--light">Read the story</a>
    </div>
  </div>
</section>

<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectRow from '$lib/components/ProjectRow.svelte';
  import { projects } from '$lib/data/projects.js';
  import { journalArticles } from '$lib/data/journal.js';
  import {
    siteName,
    siteTagline,
    siteDescription,
    siteUrl,
    contactEmail,
    githubOrgUrl,
    githubMaintainerUrl,
  } from '$lib/site.js';

  const latestNote = journalArticles[0];

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

<section class="rd-hero">
  <div class="container">
    <div class="rd-hero__grid">
      <h1 class="rd-hero__title">A home for systems and ideas.</h1>

      <div class="rd-hero__aside">
        <p class="rd-hero__deck">
          Qouver finds overlooked opportunities, turns them into useful systems,
          and shares what it learns.
        </p>
        <div class="rd-hero__actions">
          <a class="rd-btn" href="#systems">Read the systems</a>
          <a class="rd-link-line" href="mailto:{contactEmail}">{contactEmail}</a>
        </div>
      </div>
    </div>

    <div class="rd-hero__motto">
      <p>Built from what others leave behind.</p>
      <span>qouver.com</span>
    </div>
  </div>
</section>

<section class="rd-ledger-section" id="systems">
  <div class="container">
    <div class="rd-sec-head">
      <div>
        <p class="rd-kicker">Production systems</p>
        <h2>Four systems, built and operated.</h2>
      </div>
      <p class="rd-sec-head__note">
        Three run in production today; one was retired into Majadu. Status is
        marked on every entry, and live systems open from here.
      </p>
    </div>

    <div class="rd-ledger">
      <div class="rd-ledger__labels" aria-hidden="true">
        <span>Index</span>
        <span>System</span>
        <span>Stack</span>
        <span>Open</span>
      </div>

      {#each projects as project}
        <ProjectRow {project} />
      {/each}
    </div>
  </div>
</section>

<section class="rd-method" aria-label="How Qouver works">
  <div class="container rd-method__grid">
    <div class="rd-method__item">
      <span class="rd-method__num">01</span>
      <h3>Find value in plain sight.</h3>
      <p>
        Valuable things often sit unindexed or overlooked: the gap in a community,
        the pattern in a dataset, the tool nobody bothered to build.
      </p>
    </div>
    <div class="rd-method__item">
      <span class="rd-method__num">02</span>
      <h3>Build real production systems.</h3>
      <p>
        Not prototypes. Not pitch decks. Software running in production, handling
        real workload, and earning its place.
      </p>
    </div>
    <div class="rd-method__item">
      <span class="rd-method__num">03</span>
      <h3>Document every lesson.</h3>
      <p>
        What is built gets documented. Architecture post-mortems and open technical
        essays mean the next problem starts with context.
      </p>
    </div>
  </div>
</section>

<section class="rd-notes" id="notes">
  <div class="container rd-notes__grid">
    <p class="rd-kicker">Latest note</p>
    {#if latestNote}
      <article class="rd-notes__main">
        <p class="rd-notes__meta">
          {latestNote.date} / {latestNote.category} / {latestNote.readTime}
        </p>
        <h2 class="rd-notes__title">
          <a href="/journal/{latestNote.slug}">{latestNote.title}</a>
        </h2>
        <p class="rd-notes__summary">{latestNote.summary}</p>
        <a class="rd-link-line" href="/journal">All notes</a>
      </article>
    {/if}
  </div>
</section>

<section class="rd-manifesto" id="about">
  <div class="container">
    <p class="rd-manifesto__quote">
      Find what others walk past. <em>Build something useful from it.</em> Leave notes
      for whoever comes next.
    </p>
    <div class="rd-manifesto__row">
      <span class="rd-kicker rd-kicker--on-ink">Operational manifesto</span>
      <a class="rd-link-line rd-link-line--light" href="/about">Read the story</a>
    </div>
  </div>
</section>

<section class="rd-contact-band" id="contact">
  <div class="container rd-contact-band__grid">
    <div>
      <h2>Questions, a project idea, or something worth talking about.</h2>
      <p class="rd-contact-band__copy">Direct is fine.</p>
    </div>
    <div>
      <a class="rd-mailto" href="mailto:{contactEmail}">{contactEmail}</a>
      <div class="rd-contact-band__links">
        <a href={githubOrgUrl} target="_blank" rel="noopener">github.com/qouver</a>
        <a href={githubMaintainerUrl} target="_blank" rel="noopener">github.com/nferdazel</a>
      </div>
    </div>
  </div>
</section>

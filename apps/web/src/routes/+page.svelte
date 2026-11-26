<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectRow from '$lib/components/ProjectRow.svelte';
  import MailLink from '$lib/components/MailLink.svelte';
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

  const latest = journalArticles[0];
  const older = journalArticles.slice(1, 3);
  const liveCount = projects.filter((project) => project.status !== 'Archived').length;
  const archivedCount = projects.length - liveCount;
  const pad = (n: number) => String(n).padStart(2, '0');

  const schemaJson = JSON.stringify([
    {
      '@context': 'https://schema.org',
      '@type': 'Organization',
      name: 'Qouver',
      url: siteUrl,
      logo: `${siteUrl}/assets/q-mark.svg`,
      email: contactEmail,
      description: siteDescription,
      sameAs: ['https://github.com/qouver', 'https://github.com/nferdazel'],
    },
    {
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      name: 'Qouver',
      url: siteUrl,
      description: 'A home for systems and ideas. Find value. Build systems. Share knowledge.',
    },
  ]);
</script>

<SeoHead title="{siteName} · {siteTagline}" description={siteDescription} path="/" />

<svelte:head>
  {@html `<script type="application/ld+json">${schemaJson}</script>`}
</svelte:head>

<section class="hero">
  <div class="wrap hero__grid">
    <div class="hero__main">
      <h1>A home for systems and ideas.</h1>
    </div>
    <div class="hero__side">
      <p>
        Qouver finds overlooked opportunities, turns them into useful systems, and
        shares what it learns.
      </p>
      <MailLink />
    </div>
    <p class="hero__deck">
      {projects.length} systems, built and operated. {liveCount} run for someone today.
      {archivedCount} are archived and still documented.
    </p>
    <div class="hero__cta">
      <a class="btn" href="#register">See the register</a>
      <a class="btn btn--ghost" href="/contact">Start a conversation</a>
    </div>
  </div>
</section>

<div class="statusbar">
  <div class="wrap statusbar__in">
    <div class="statusbar__cell">
      <span class="n">{pad(projects.length)}</span>
      <span class="t">Systems on record</span>
    </div>
    <div class="statusbar__cell">
      <span class="n">{pad(liveCount)}</span>
      <span class="t">In service</span>
    </div>
    <div class="statusbar__cell">
      <span class="n">{pad(archivedCount)}</span>
      <span class="t">Archived</span>
    </div>
    <div class="statusbar__cell">
      <span class="n">{latest?.date ?? 'None'}</span>
      <span class="t">Latest journal entry</span>
    </div>
  </div>
</div>

<section class="sec sec--airy" id="register">
  <div class="wrap">
    <div class="sec__head">
      <div class="sec__head__main">
        <p class="kicker">System register</p>
        <h2>Built, run, written down</h2>
      </div>
      <p>
        Status is stated on every row. Every row opens its system record,
        operating or archived.
      </p>
    </div>

    <div class="board">
      <div class="board__labels" aria-hidden="true">
        <span>No.</span>
        <span>System</span>
        <span>Domain</span>
        <span>Stack</span>
        <span>Status</span>
      </div>
      {#each projects as project}
        <ProjectRow {project} />
      {/each}
    </div>
  </div>
</section>

<section class="method" id="method" aria-label="How Qouver works">
  <div class="wrap">
    <div class="method__head">
      <h2>Working method</h2>
      <p>Three steps, in this order. Every system on the register came out of them.</p>
    </div>
    <div class="method__grid">
      <div class="method__item">
        <span class="n">01</span>
        <h3>Find value in plain sight</h3>
        <p>
          Valuable things often sit unindexed or overlooked: the gap in a community,
          the pattern in a dataset, the tool nobody bothered to build.
        </p>
      </div>
      <div class="method__item">
        <span class="n">02</span>
        <h3>Build real production systems</h3>
        <p>
          Not prototypes. Not pitch decks. Software running in production, handling
          real workload, and earning its place.
        </p>
      </div>
      <div class="method__item">
        <span class="n">03</span>
        <h3>Document every lesson</h3>
        <p>
          What is built gets documented. Architecture post-mortems and open technical
          essays mean the next problem starts with context.
        </p>
      </div>
    </div>
  </div>
</section>

<section class="sec sec--airy" id="journal">
  <div class="wrap journal">
    {#if latest}
      <article class="journal__main">
        <p class="kicker">Journal / latest entry</p>
        <h2><a href="/journal/{latest.slug}">{latest.title}</a></h2>
        <p class="journal__meta">{latest.date} · {latest.category} · {latest.readTime}</p>
        <p>{latest.summary}</p>
        <p class="journal__more">
          <a class="btn btn--ghost" href="/journal">All notes</a>
        </p>
      </article>
    {/if}
    <div class="journal__list">
      {#each older as article}
        <a class="ji" href="/journal/{article.slug}">
          <span class="d">{article.date} · {article.category}</span>
          <span class="t">{article.title}</span>
        </a>
      {/each}
    </div>
  </div>
</section>

<section class="band" id="contact">
  <div class="wrap band__grid">
    <h2>Questions, a project idea, or something worth talking about.</h2>
    <div class="band__side">
      <MailLink class="band__mail" />
      <div class="band__links">
        <a href={githubOrgUrl} target="_blank" rel="noopener">github.com/qouver</a>
        <a href={githubMaintainerUrl} target="_blank" rel="noopener">github.com/nferdazel</a>
      </div>
    </div>
  </div>
</section>

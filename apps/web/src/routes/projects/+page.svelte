<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectRow from '$lib/components/ProjectRow.svelte';
  import { projects } from '$lib/data/projects.js';
  import {
    contactEmail,
    githubOrgUrl,
    githubMaintainerUrl,
  } from '$lib/site.js';
</script>

<SeoHead
  title="Projects · Qouver"
  description="The systems under the Qouver umbrella: Skyward, Majadu Tools, and SDS Management: simulation, community systems, and compliance tools."
  path="/projects"
/>

<section class="rd-page-head">
  <div class="container">
    <div class="rd-page-head__meta">
      <p class="rd-kicker">Catalogue / four systems</p>
    </div>
    <h1 class="rd-page-title">Production Systems</h1>
    <p class="rd-page-head__lead">
      Live, in production, or archived, each one earned its place. Built to solve
      real problems with disciplined software craft.
    </p>
    <p class="rd-page-head__contact">
      Working on something similar? <a href="mailto:{contactEmail}">{contactEmail}</a>
    </p>
  </div>
</section>

<section class="rd-catalogue">
  <div class="container">
    <div class="rd-ledger">
      <div class="rd-ledger__labels" aria-hidden="true">
        <span>Index</span>
        <span>System</span>
        <span>Stack</span>
        <span>Open</span>
      </div>

      {#each projects as project}
        <ProjectRow {project} level={2} showFocus />
      {/each}
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

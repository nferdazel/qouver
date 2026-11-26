<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectRow from '$lib/components/ProjectRow.svelte';
  import MailLink from '$lib/components/MailLink.svelte';
  import { projects } from '$lib/data/projects.js';
  import { githubOrgUrl, githubMaintainerUrl } from '$lib/site.js';
</script>

<SeoHead
  title="Projects · Qouver"
  description="The systems under the Qouver umbrella: Majadu Tools, SDS Management, Skyward and M-DEF: community systems, compliance tools, and a simulation."
  path="/projects"
/>

<section class="pagehead">
  <div class="wrap pagehead__grid">
    <div class="pagehead__main">
      <p class="kicker">Catalogue / {projects.length} systems</p>
      <h1 class="pagehead__title">Production Systems</h1>
    </div>
    <div class="pagehead__side">
      <p>
        Live, in production, or archived, each one earned its place. Built to solve
        real problems with disciplined software craft.
      </p>
      <p>Working on something similar? <MailLink /></p>
    </div>
  </div>
</section>

<section class="sec sec--airy">
  <div class="wrap">
    <div class="board">
      <div class="board__labels" aria-hidden="true">
        <span>No.</span>
        <span>System</span>
        <span>Domain</span>
        <span>Stack</span>
        <span>Status</span>
      </div>
      {#each projects as project}
        <ProjectRow {project} showFocus />
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

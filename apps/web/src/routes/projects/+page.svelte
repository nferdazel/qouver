<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectCard from '$lib/components/ProjectCard.svelte';
  import { projects } from '$lib/data/projects.js';
</script>

<SeoHead
  title="Projects · Qouver"
  description="The systems under the Qouver umbrella: Skyward, Majadu Tools, and SDS Management: simulation, community systems, and compliance tools."
  path="/projects"
/>

<section class="page-head container">
  <div class="page-head__meta">
    <span class="badge badge--bronze">CATALOGUE</span>
  </div>
  <h1 class="page-title">Production Systems</h1>
  <p class="lead mt-2">
    Live, in production, or archived, each one earned its place. Built to solve real problems with disciplined software craft.
  </p>
</section>

<section class="section container">
  <div class="projects-grid">
    {#each projects as project}
      <ProjectCard {project} />
    {/each}
  </div>
</section>

<script lang="ts">
  import type { Project } from '$lib/data/projects.js';
  import ProjectStatusBadge from './ProjectStatusBadge.svelte';

  interface Props {
    project: Project;
    showFocus?: boolean;
  }

  let { project, showFocus = false }: Props = $props();

  // The register shows the external destination where one exists, so a row
  // never needs a second "open" column. Archived rows state the record instead.
  const host = $derived(project.url ? new URL(project.url).host : null);
</script>

<article class="row">
  <span class="idx">{project.index}</span>
  <span class="nm">
    <a href="/projects/{project.slug}">{project.name}</a>
    <small>{project.tagline}</small>
    {#if showFocus}
      <span class="focus">
        {#each project.focus as item}
          <span>{item}</span>
        {/each}
      </span>
    {/if}
  </span>
  <span class="dm">{project.category}</span>
  <span class="sq">{project.stack}</span>
  <span class="st"><ProjectStatusBadge status={project.status} /></span>
  <span class="go">
    {#if project.url && host}
      <a href={project.url} target="_blank" rel="noopener" title={project.url}>{host}</a>
    {:else}
      <em>Record kept</em>
    {/if}
  </span>
</article>

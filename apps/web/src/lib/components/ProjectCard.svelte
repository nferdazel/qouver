<script lang="ts">
  import type { Project } from '$lib/data/projects.js';
  import ProjectStatusBadge from './ProjectStatusBadge.svelte';

  interface Props {
    project: Project;
  }

  let { project }: Props = $props();
</script>

<article class="project-card">
  <span class="project-card__index">{project.index}</span>
  <div class="project-card__body">
    <div class="project-card__head">
      <span class="project-card__category">{project.category.toUpperCase()}</span>
      <ProjectStatusBadge status={project.status} />
    </div>
    <h3 class="project-card__name">
      <a href="/projects/{project.slug}">{project.name}</a>
    </h3>
    <p class="project-card__desc">{project.description}</p>
    <div class="project-card__stack-list">
      {#each project.stackItems as item}
        <span class="stack-pill">{item}</span>
      {/each}
    </div>
  </div>
  <div class="project-card__foot">
    <a href="/projects/{project.slug}" class="link-action">Case Study</a>
    {#if project.url}
      <a
        href={project.url}
        target="_blank"
        rel="noopener"
        class="btn btn--ghost"
      >
        {project.urlLabel ?? 'VISIT'} ↗
      </a>
    {/if}
  </div>
</article>

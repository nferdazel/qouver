<script lang="ts">
  import type { Project } from '$lib/data/projects.js';

  interface Props {
    project: Project;
    level?: 2 | 3;
    showFocus?: boolean;
  }

  let { project, level = 3, showFocus = false }: Props = $props();

  const heading = $derived(level === 2 ? 'h2' : 'h3');
  const statusModifier = $derived(
    project.status === 'Live'
      ? 'rd-status--live'
      : project.status === 'Backend'
        ? 'rd-status--backend'
        : '',
  );
  const urlLabel = $derived(project.urlLabel === 'API' ? 'API' : 'Visit');
</script>

<article class="rd-ledger-row">
  <span class="rd-ledger-row__index">{project.index}</span>
  <div class="rd-ledger-row__main">
    <p class="rd-ledger-row__meta">
      <span class="rd-status {statusModifier}">
        <span class="rd-status__dot"></span>{project.status}
      </span>
      <span>{project.category}</span>
    </p>
    <svelte:element this={heading} class="rd-ledger-row__name">
      <a href="/projects/{project.slug}">{project.name}</a>
    </svelte:element>
    <p class="rd-ledger-row__desc">{project.description}</p>
    {#if showFocus}
      <div class="rd-focus-list" aria-label="Focus areas">
        {#each project.focus as item}
          <span>{item}</span>
        {/each}
      </div>
    {/if}
  </div>
  <div class="rd-ledger-row__stack">{project.stack}</div>
  <div class="rd-ledger-row__actions">
    <a class="rd-link-line" href="/projects/{project.slug}">Case study</a>
    {#if project.url}
      <a
        class="rd-btn rd-btn--ghost"
        href={project.url}
        target="_blank"
        rel="noopener">{urlLabel} ↗</a
      >
    {/if}
  </div>
</article>

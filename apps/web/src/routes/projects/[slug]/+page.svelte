<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectStatusBadge from '$lib/components/ProjectStatusBadge.svelte';
  import type { PageData } from './$types.js';

  let { data }: { data: PageData } = $props();
  const project = $derived(data.project);
  const cs = $derived(project.caseStudy);
</script>

{#if cs}
  <SeoHead
    title="{project.name} · Technical Case Study · Qouver"
    description={cs.overview}
    path="/projects/{project.slug}"
  />

  <section class="page-head container">
    <div class="page-head__meta">
      <a href="/projects" class="link link--back">← Projects</a>
      <span class="label">Case Study</span>
    </div>
    <h1 class="page-title">{project.name}</h1>
    <p class="lead mt-2">{cs.title}</p>
    <div class="project-detail__meta-bar mt-3">
      <div class="project-detail__meta-item">
        <span class="label">Category</span>
        <span class="project-detail__meta-val">{project.category}</span>
      </div>
      <div class="project-detail__meta-item">
        <span class="label">Status</span>
        <ProjectStatusBadge status={project.status} />
      </div>
      <div class="project-detail__meta-item">
        <span class="label">Stack</span>
        <span class="project-detail__meta-val">{project.stack}</span>
      </div>
      {#if project.url}
        <div class="project-detail__meta-item">
          <span class="label">Live Site</span>
          <a
            href={project.url}
            target="_blank"
            rel="noopener"
            class="link"
          >
            {project.urlLabel ?? 'VISIT'} ↗
          </a>
        </div>
      {/if}
    </div>
  </section>

  <section class="section container">
    <div class="editorial">
      <div class="editorial__label">01 / Context</div>
      <div>
        <h2 class="h3">Overview & Problem</h2>
        <p class="body mt-2">{cs.overview}</p>
        <p class="body">{cs.problem}</p>
      </div>
    </div>

    <div class="editorial mt-3">
      <div class="editorial__label">02 / System</div>
      <div>
        <h2 class="h3">Architecture</h2>
        <p class="body mt-2">{cs.architecture}</p>
      </div>
    </div>

    <div class="editorial mt-3">
      <div class="editorial__label">03 / Decisions</div>
      <div>
        <h2 class="h3">Key Decisions &amp; Trade-Offs</h2>
        <ol class="case-decisions mt-2">
          {#each cs.decisions as decision, i}
            <li class="case-decision-item">
              <span class="case-decision-item__num" aria-hidden="true">
                {String(i + 1).padStart(2, '0')}
              </span>
              <h3 class="case-decision-item__title">{decision.heading}</h3>
              <p class="body">{decision.explanation}</p>
            </li>
          {/each}
        </ol>
      </div>
    </div>

    <div class="editorial mt-3">
      <div class="editorial__label">04 / Retrospective</div>
      <div>
        <h2 class="h3">Takeaways</h2>
        <p class="body mt-2">{cs.takeaways}</p>
      </div>
    </div>
  </section>
{:else}
  <section class="page-head container">
    <h1 class="page-title">Case study not found.</h1>
    <div class="mt-3">
      <a href="/projects" class="link link--back">← All projects</a>
    </div>
  </section>
{/if}

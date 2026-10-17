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
      <a href="/projects" class="link">← Projects</a>
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
        <h2 class="h3">Key Decisions & Trade-Offs</h2>
        <div class="decision-list mt-2">
          {#each cs.decisions as decision}
            <div class="decision-item">
              <h4 class="decision-item__heading">{decision.heading}</h4>
              <p class="body">{decision.explanation}</p>
            </div>
          {/each}
        </div>
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
      <a href="/projects" class="link">← All projects</a>
    </div>
  </section>
{/if}

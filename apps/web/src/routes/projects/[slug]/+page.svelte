<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import ProjectStatusBadge from '$lib/components/ProjectStatusBadge.svelte';
  import RecordDiagram from '$lib/components/RecordDiagram.svelte';
  import type { PageData } from './$types.js';

  let { data }: { data: PageData } = $props();
  const project = $derived(data.project);
  const cs = $derived(project.caseStudy);

  const siteLabel = $derived(project.urlLabel === 'API' ? 'API' : 'Live site');
</script>

{#if cs}
  <SeoHead
    title="{project.name} · System record {project.index} · Qouver"
    description={cs.overview}
    path="/projects/{project.slug}"
    ogType="article"
  />

  <section class="rec">
    <div class="wrap wrap--doc">
      <div class="rec__top">
        <a class="kicker" href="/projects">Register / back to the system list</a>
        <span class="kicker kicker--dim">System record {project.index}</span>
      </div>
      <h1>{project.name}</h1>
      <p class="stand">{cs.overview}</p>
      <dl class="rec__meta">
        <div>
          <dt>Status</dt>
          <dd><ProjectStatusBadge status={project.status} /></dd>
        </div>
        <div>
          <dt>Domain</dt>
          <dd>{project.category}</dd>
        </div>
        <div>
          <dt>Stack</dt>
          <dd>{project.stack}</dd>
        </div>
        {#if project.url}
          <div>
            <dt>{siteLabel}</dt>
            <dd>
              <a href={project.url} target="_blank" rel="noopener">{project.url.replace('https://', '')}</a>
            </dd>
          </div>
        {/if}
      </dl>
    </div>
  </section>

  <div class="wrap wrap--doc doc">
    <aside class="rail">
      <div class="rail__in">
        <span class="kicker">On this record</span>
        <nav aria-label="Sections">
          <a href="#context"><span class="n">01</span> Context</a>
          <a href="#system"><span class="n">02</span> System</a>
          <a href="#decisions"><span class="n">03</span> Decisions</a>
          <a href="#retro"><span class="n">04</span> Retrospective</a>
        </nav>
        {#if project.status === 'Backend'}
          <p>
            Status is Backend, not Live. Qouver builds and operates the API and the
            data behind it, and the record stays scoped to that.
          </p>
        {/if}
      </div>
    </aside>

    <div class="text">
      <section class="part" id="context">
        <div class="part__label"><span class="n">01</span><span class="kicker">Context</span></div>
        <h2>Overview &amp; Problem</h2>
        <p>{cs.overview}</p>
        <p>{cs.problem}</p>
      </section>

      <section class="part" id="system">
        <div class="part__label"><span class="n">02</span><span class="kicker">System</span></div>
        <h2>Architecture</h2>
        <p>{cs.architecture}</p>
        {#if cs.diagram}
          <RecordDiagram diagram={cs.diagram} index={1} />
        {/if}
      </section>

      <section class="part" id="decisions">
        <div class="part__label"><span class="n">03</span><span class="kicker">Decisions</span></div>
        <h2>Key Decisions &amp; Trade-Offs</h2>
        <ol class="decisions">
          {#each cs.decisions as decision, i}
            <li>
              <span class="n">{String(i + 1).padStart(2, '0')}</span>
              <div>
                <h3>{decision.heading}</h3>
                <p>{decision.explanation}</p>
              </div>
            </li>
          {/each}
        </ol>
      </section>

      <section class="part" id="retro">
        <div class="part__label"><span class="n">04</span><span class="kicker">Retrospective</span></div>
        <h2>Takeaways</h2>
        <p>{cs.takeaways}</p>
      </section>
    </div>
  </div>

  <div class="end">
    <div class="wrap wrap--doc end__in">
      <span class="kicker">End of record {project.index}</span>
      <a href="/projects">Back to the register</a>
    </div>
  </div>

  <section class="band" id="contact">
    <div class="wrap wrap--doc band__grid">
      <h2>Questions, a project idea, or something worth talking about.</h2>
      <div class="band__side">
        <a class="band__mail" href="/contact">hello@qouver.com</a>
        <div class="band__links">
          <a href="https://github.com/qouver" target="_blank" rel="noopener">github.com/qouver</a>
          <a href="https://github.com/nferdazel" target="_blank" rel="noopener">github.com/nferdazel</a>
        </div>
      </div>
    </div>
  </section>
{:else}
  <section class="notfound wrap">
    <h1 class="notfound__title">Case study not found.</h1>
    <p class="notfound__body">Nothing is filed under this system record.</p>
    <div class="notfound__links">
      <a class="btn" href="/projects">Back to the register</a>
    </div>
  </section>
{/if}

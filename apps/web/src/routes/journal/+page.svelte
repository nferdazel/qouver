<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import MailLink from '$lib/components/MailLink.svelte';
  import { journalArticles } from '$lib/data/journal.js';
  import { githubOrgUrl, githubMaintainerUrl } from '$lib/site.js';
</script>

<SeoHead
  title="Journal · Qouver"
  description="Notes on systems, software craft, architecture, and independent building."
  path="/journal"
/>

<section class="pagehead">
  <div class="wrap pagehead__grid">
    <div class="pagehead__main">
      <p class="kicker">Journal / {journalArticles.length} entries</p>
      <h1 class="pagehead__title">Journal</h1>
    </div>
    <div class="pagehead__side">
      <p>Notes on software craft, architecture decisions, and systems design.</p>
    </div>
  </div>
</section>

<section class="sec sec--airy">
  <div class="wrap">
    <div class="journal-list">
      {#each journalArticles as article}
        <article class="journal-item">
          <span class="journal-item__date">{article.date}</span>
          <h2 class="journal-item__title">
            <a href="/journal/{article.slug}">{article.title}</a>
          </h2>
          <span class="journal-item__meta">{article.category} · {article.readTime}</span>
        </article>
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

<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import { journalArticles } from '$lib/data/journal.js';
</script>

<SeoHead
  title="Journal · Qouver"
  description="Notes on systems, software craft, architecture, and independent building."
  path="/journal"
/>

<section class="page-head container">
  <h1 class="page-title">Journal</h1>
  <p class="lead mt-2">
    Notes on software craft, architecture decisions, and systems design.
  </p>
</section>

<section class="section container">
  <div class="journal-list">
    {#each journalArticles as article}
      <article class="journal-item">
        <div class="journal-item__side">
          <div class="journal-item__date">{article.date}</div>
          <div class="journal-item__tag">
            <span class="journal-item__category">{article.category}</span>
            <span class="journal-item__dot">·</span>
            <span class="journal-item__time">{article.readTime}</span>
          </div>
        </div>
        <div class="journal-item__main">
          <h2 class="journal-item__title">
            <a href="/journal/{article.slug}">{article.title}</a>
          </h2>
        </div>
      </article>
    {/each}
  </div>
</section>

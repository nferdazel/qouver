<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import MailLink from '$lib/components/MailLink.svelte';
  import type { PageData } from './$types.js';

  let { data }: { data: PageData } = $props();
  const article = $derived(data.article);
</script>

<SeoHead
  title="{article.title} · Journal · Qouver"
  description={article.summary}
  path="/journal/{article.slug}"
  ogType="article"
/>

<section class="rec rec--article">
  <div class="wrap wrap--doc">
    <div class="rec__top">
      <a class="kicker" href="/journal">Journal / back to all entries</a>
      <span class="kicker kicker--dim">{article.category}</span>
    </div>
    <h1 class="rec__title">{article.title}</h1>
    <p class="article-reader__meta">{article.date} · {article.category} · {article.readTime}</p>
  </div>
</section>

<div class="wrap wrap--doc doc doc--single">
  <div class="text">
    <div class="article-reader__body">
      {#each article.paragraphs as paragraph}
        <p>{paragraph}</p>
      {/each}

      {#if article.quote}
        <blockquote>
          <p>{article.quote}</p>
        </blockquote>
      {/if}

      {#if article.codeSnippet}
        <pre><code>{article.codeSnippet}</code></pre>
      {/if}
    </div>

    <div class="article-reader__foot">
      <a class="btn btn--ghost" href="/journal">All entries</a>
    </div>
  </div>
</div>

<section class="band" id="contact">
  <div class="wrap wrap--doc band__grid">
    <h2>Questions, a project idea, or something worth talking about.</h2>
    <div class="band__side">
      <MailLink class="band__mail" />
      <div class="band__links">
        <a href="https://github.com/qouver" target="_blank" rel="noopener">github.com/qouver</a>
        <a href="https://github.com/nferdazel" target="_blank" rel="noopener">github.com/nferdazel</a>
      </div>
    </div>
  </div>
</section>

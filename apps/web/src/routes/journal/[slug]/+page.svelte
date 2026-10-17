<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
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

<section class="container article-reader">
  <div class="article-reader__header">
    <a href="/journal" class="link link--dim">← Back to Journal</a>
    <div class="article-reader__meta mt-3">
      <span class="journal-card__category">{article.category}</span>
      <span class="label">{article.date}</span>
      <span class="label">·</span>
      <span class="label">{article.readTime}</span>
    </div>
    <h1 class="article-reader__title mt-2">{article.title}</h1>
  </div>

  <div class="article-reader__body">
    {#each article.paragraphs as paragraph}
      <p>{paragraph}</p>
    {/each}

    {#if article.quote}
      <blockquote>
        <p>“{article.quote}”</p>
      </blockquote>
    {/if}

    {#if article.codeSnippet}
      <pre><code>{article.codeSnippet}</code></pre>
    {/if}
  </div>

  <div class="divider mt-3"></div>

  <div class="pt-3">
    <a href="/journal" class="link link--dim">← Back to all articles</a>
  </div>
</section>

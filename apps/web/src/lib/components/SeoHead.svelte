<script lang="ts">
  import { siteName, siteUrl, ogImageUrl } from '$lib/site.js';

  interface Props {
    title: string;
    description: string;
    path: string;
    ogType?: string;
  }

  let { title, description, path, ogType = 'website' }: Props = $props();

  const fullUrl = $derived(`${siteUrl}${path}`);
</script>

<svelte:head>
  <title>{title}</title>
  <meta name="description" content={description} />
  <link rel="canonical" href={fullUrl} />

  <!-- OpenGraph -->
  <meta property="og:type" content={ogType} />
  <meta property="og:site_name" content={siteName} />
  <meta property="og:title" content={title} />
  <meta property="og:description" content={description} />
  <meta property="og:url" content={fullUrl} />
  <meta property="og:image" content={ogImageUrl} />

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content={title} />
  <meta name="twitter:description" content={description} />
  <meta name="twitter:image" content={ogImageUrl} />
</svelte:head>

<script lang="ts">
  import { page } from '$app/state';
  import SeoHead from '$lib/components/SeoHead.svelte';
</script>

<SeoHead
  title="Page not found · Qouver"
  description="The page you are looking for does not exist. Back to the home of systems and ideas."
  path="/404.html"
/>

<section class="page-head container">
  <div class="page-head__meta">
    <span class="label">Error {page.status}</span>
  </div>
  <h1 class="page-title">Page not found.</h1>
  <p class="lead mt-2">
    The page you are looking for does not exist, or was prospected away.
  </p>
</section>

<section class="section container">
  <a href="/" class="link">Back to home</a>
</section>

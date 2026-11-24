<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
</script>

<SeoHead
  title="Page not found · Qouver"
  description="The page you are looking for does not exist. Back to the home of systems and ideas."
  path="/404"
/>

<section class="page-head container">
  <div class="page-head__meta">
    <span class="label">Error 404</span>
  </div>
  <h1 class="page-title">Page not found.</h1>
  <p class="lead mt-2">
    The page you are looking for does not exist, or was prospected away.
  </p>
</section>

<section class="section container">
  <div class="rd-404">
    <p class="body">
      Nothing is filed under this address. The four systems and the journal are
      still where they were.
    </p>
    <div class="rd-404__links">
      <a href="/" class="rd-btn">Back to home</a>
      <a href="/projects" class="rd-link-line">Browse the systems</a>
    </div>
  </div>
</section>

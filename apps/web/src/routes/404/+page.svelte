<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
</script>

<SeoHead
  title="Page not found · Qouver"
  description="The page you are looking for does not exist. Back to the home of systems and ideas."
  path="/404"
/>

<section class="notfound wrap">
  <p class="kicker">Error 404</p>
  <h1 class="notfound__title">Page not found.</h1>
  <p class="notfound__body">
    Nothing is filed under this address. The four systems and the journal are still where
    they were.
  </p>
  <div class="notfound__links">
    <a class="btn" href="/">Back to home</a>
    <a class="btn btn--ghost" href="/projects">Browse the systems</a>
  </div>
</section>

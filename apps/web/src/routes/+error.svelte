<script lang="ts">
  import { page } from '$app/state';
  import SeoHead from '$lib/components/SeoHead.svelte';
</script>

<SeoHead
  title="Page not found · Qouver"
  description="The page you are looking for does not exist. Back to the home of systems and ideas."
  path="/404"
/>

<section class="notfound wrap">
  <p class="kicker">Error {page.status}</p>
  <h1 class="notfound__title">Page not found.</h1>
  <p class="notfound__body">
    The page you are looking for does not exist, or was prospected away.
  </p>
  <div class="notfound__links">
    <a class="btn" href="/">Back to home</a>
    <a class="btn btn--ghost" href="/projects">Browse the systems</a>
  </div>
</section>

<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
</script>

<SeoHead
  title="About · Qouver"
  description="Qouver is a home for systems and ideas. Independent software craft, production principles, and open documentation."
  path="/about"
/>

<section class="page-head container">
  <h1 class="page-title">About Qouver</h1>
  <p class="lead mt-2">
    Qouver is an umbrella home for software systems, tools, and technical experiments, designed and maintained with disciplined software craft.
  </p>
</section>

<section class="section container">
  <div class="editorial">
    <div class="editorial__label">01 / Builder</div>
    <div>
      <h2 class="h3">One craftsman working in public</h2>
      <p class="body mt-2">
        Qouver is built and maintained by <strong>Sachiel</strong>, <a href="https://github.com/nferdazel" target="_blank" rel="noopener">@nferdazel</a> on GitHub. An independent systems builder focusing on tools that solve real problems.
      </p>
      <p class="body">
        No pitch decks, no corporate bloat. Just software designed with high standards of reliability, performance, and maintainability.
      </p>
    </div>
  </div>

  <div class="editorial mt-3">
    <div class="editorial__label">02 / Principles</div>
    <div>
      <h2 class="h3">Production Readiness &gt; Prototype Hype</h2>
      <p class="body mt-2">
        We do not build disposable demos. Systems are engineered to run continuously in production, handle real user workloads, and earn their place.
      </p>
      <h2 class="h3 mt-3">Authoritative Engines &amp; Static-First Web</h2>
      <p class="body mt-2">
        Business logic and calculations belong on deterministic backend servers. The web tier stays zero-JS, static, and lightning fast.
      </p>
      <h2 class="h3 mt-3">Document Everything &amp; Share Knowledge</h2>
      <p class="body mt-2">
        Every trade-off, architecture decision, and lesson learned is written down, so the next problem starts with clarity rather than a blank page.
      </p>
    </div>
  </div>

  <div class="editorial mt-3">
    <div class="editorial__label">03 / Stack</div>
    <div>
      <h2 class="h3">Production Infrastructure</h2>
      <p class="body mt-2">
        Backend services in Nim and Go, persistence in PostgreSQL, presentation layer in SvelteKit with static pre-rendering. Deployed using rootless Podman containers behind Caddy TLS on independent Linux VPS host.
      </p>
    </div>
  </div>
</section>

<section class="manifesto section">
  <div class="container">
    <p class="manifesto__quote">
      Find value in what others walk past. <em>Build useful systems from it, and write down what you learned.</em>
    </p>
    <div class="manifesto__row">
      <span class="manifesto__lbl">Guiding principle</span>
      <a href="/contact" class="link-action link-action--light">Get in touch</a>
    </div>
  </div>
</section>

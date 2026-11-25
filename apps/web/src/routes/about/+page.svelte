<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
</script>

<SeoHead
  title="About · Qouver"
  description="Qouver is a home for systems and ideas. Independent software craft, production principles, and open documentation."
  path="/about"
/>

<section class="pagehead">
  <div class="wrap pagehead__grid">
    <div class="pagehead__main">
      <p class="kicker">About / the builder</p>
      <h1 class="pagehead__title">About Qouver</h1>
    </div>
    <div class="pagehead__side">
      <p>
        Qouver is an umbrella home for software systems, tools, and technical
        experiments, designed and maintained with disciplined software craft.
      </p>
    </div>
  </div>
</section>

<section class="sec sec--airy">
  <div class="wrap">
    <div class="editorial">
      <p class="editorial__label">01 / Builder</p>
      <div class="editorial__body">
        <h2>One craftsman working in public</h2>
        <p>
          Qouver is built and maintained by <strong>Sachiel</strong>,
          <a href="https://github.com/nferdazel" target="_blank" rel="noopener">@nferdazel</a>
          on GitHub. An independent systems builder focusing on tools that solve real
          problems.
        </p>
        <p>
          No pitch decks, no corporate bloat. Just software designed with high standards
          of reliability, performance, and maintainability.
        </p>
      </div>
    </div>

    <div class="editorial">
      <p class="editorial__label">02 / Principles</p>
      <div class="editorial__body">
        <h2>Production Readiness &gt; Prototype Hype</h2>
        <p>
          We do not build disposable demos. Systems are engineered to run continuously in
          production, handle real user workloads, and earn their place.
        </p>
        <h2>Authoritative Engines &amp; Static-First Web</h2>
        <p>
          Business logic and calculations belong on deterministic backend servers. The web
          tier is prerendered and static: HTML first, with a small hydration bundle for the
          parts that need it.
        </p>
        <h2>Document Everything &amp; Share Knowledge</h2>
        <p>
          Every trade-off, architecture decision, and lesson learned is written down, so
          the next problem starts with clarity rather than a blank page.
        </p>
      </div>
    </div>

    <div class="editorial">
      <p class="editorial__label">03 / Stack</p>
      <div class="editorial__body">
        <h2>Production Infrastructure</h2>
        <p>
          Backend services in Nim and Go, persistence in PostgreSQL, presentation layer in
          SvelteKit with static pre-rendering. Deployed using rootless Podman containers
          behind Caddy TLS on independent Linux VPS host.
        </p>
      </div>
    </div>
  </div>
</section>

<section class="statement">
  <div class="wrap statement__grid">
    <p class="statement__quote">
      Find value in what others walk past. <em>Build useful systems from it, and write down what you learned.</em>
    </p>
    <div class="statement__side">
      <span class="kicker">Guiding principle</span>
      <a class="statement__link" href="/contact">Get in touch</a>
    </div>
  </div>
</section>

<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import {
    contactEmail,
    githubOrgUrl,
    githubMaintainerUrl,
  } from '$lib/site.js';

  let name = $state('');
  let email = $state('');
  let subject = $state('');
  let message = $state('');
  let status = $state<'idle' | 'submitting' | 'success' | 'error'>('idle');
  let errorMessage = $state('');

  async function handleSubmit(e: Event) {
    e.preventDefault();
    status = 'submitting';
    errorMessage = '';

    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, subject, message }),
      });

      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.message || 'Failed to send inquiry.');
      }

      status = 'success';
      name = '';
      email = '';
      subject = '';
      message = '';
    } catch (err: unknown) {
      status = 'error';
      errorMessage = err instanceof Error ? err.message : 'An error occurred';
    }
  }
</script>

<SeoHead
  title="Contact · Qouver"
  description="Get in touch with Qouver, a home for systems and ideas. hello@qouver.com, github.com/qouver."
  path="/contact"
/>

<section class="page-head container">
  <h1 class="page-title">Contact</h1>
  <p class="lead mt-2">
    Questions, a project idea, or just something worth talking about: direct is fine.
  </p>
</section>

<section class="manifesto section">
  <div class="container">
    <div class="contact-list">
      <div class="contact-row">
        <span class="contact-row__label">Email</span>
        <a class="contact-row__value" href="mailto:{contactEmail}">
          {contactEmail}
        </a>
        <span class="contact-row__note">Replies within a day or two</span>
      </div>

      <div class="contact-row">
        <span class="contact-row__label">GitHub (org)</span>
        <a
          class="contact-row__value"
          href={githubOrgUrl}
          target="_blank"
          rel="noopener"
        >
          github.com/qouver
        </a>
      </div>

      <div class="contact-row">
        <span class="contact-row__label">GitHub (maintainer)</span>
        <a
          class="contact-row__value"
          href={githubMaintainerUrl}
          target="_blank"
          rel="noopener"
        >
          github.com/nferdazel
        </a>
      </div>
    </div>
  </div>
</section>

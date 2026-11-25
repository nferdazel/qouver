<script lang="ts">
  import SeoHead from '$lib/components/SeoHead.svelte';
  import MailLink from '$lib/components/MailLink.svelte';
  import { githubOrgUrl, githubMaintainerUrl } from '$lib/site.js';

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

<section class="pagehead">
  <div class="wrap pagehead__grid">
    <div class="pagehead__main">
      <p class="kicker">Contact / direct is fine</p>
      <h1 class="pagehead__title">Contact</h1>
    </div>
    <div class="pagehead__side">
      <p>
        Questions, a project idea, or just something worth talking about: direct is fine.
      </p>
    </div>
  </div>
</section>

<section class="sec sec--airy">
  <div class="wrap">
    <div class="editorial">
      <p class="editorial__label">Inquiry</p>
      <div class="editorial__body">
        <h2>Send a dispatch</h2>
        <p>
          Direct inquiries regarding collaboration, systems architecture, or engineering
          notes.
        </p>

        {#if status === 'success'}
          <div class="form-alert form-alert--success form-alert--after" role="status">
            <p class="form-alert__title">Message received.</p>
            <p class="form-alert__body">
              Thank you for reaching out. We will review your inquiry and follow up
              directly.
            </p>
            <button type="button" class="btn btn--ghost form-alert__action" onclick={() => (status = 'idle')}>
              Send another dispatch
            </button>
          </div>
        {:else}
          <form class="contact-form" onsubmit={handleSubmit}>
            {#if status === 'error'}
              <div class="form-alert form-alert--error" role="alert">
                <p class="form-alert__title">Failed to send message</p>
                <p class="form-alert__body">
                  {errorMessage || 'Please verify your information and try again.'}
                </p>
              </div>
            {/if}

            <div class="form-row">
              <div class="form-field">
                <label for="contact-name" class="form-label">
                  Name <span class="form-required" aria-hidden="true">*</span>
                </label>
                <input
                  id="contact-name"
                  name="name"
                  type="text"
                  class="form-input"
                  bind:value={name}
                  required
                  minlength="2"
                  maxlength="100"
                  placeholder="Sachiel Ferdazel"
                  disabled={status === 'submitting'}
                />
              </div>

              <div class="form-field">
                <label for="contact-email" class="form-label">
                  Email <span class="form-required" aria-hidden="true">*</span>
                </label>
                <input
                  id="contact-email"
                  name="email"
                  type="email"
                  class="form-input"
                  bind:value={email}
                  required
                  maxlength="150"
                  placeholder="name@example.com"
                  disabled={status === 'submitting'}
                />
              </div>
            </div>

            <div class="form-field">
              <label for="contact-subject" class="form-label">
                Subject <span class="form-required" aria-hidden="true">*</span>
              </label>
              <input
                id="contact-subject"
                name="subject"
                type="text"
                class="form-input"
                bind:value={subject}
                required
                minlength="2"
                maxlength="200"
                placeholder="Architecture inquiry / Skyward backend"
                disabled={status === 'submitting'}
              />
            </div>

            <div class="form-field">
              <label for="contact-message" class="form-label">
                Message <span class="form-required" aria-hidden="true">*</span>
              </label>
              <textarea
                id="contact-message"
                name="message"
                class="form-textarea"
                rows="6"
                bind:value={message}
                required
                minlength="5"
                maxlength="5000"
                placeholder="Provide context, technical details, or notes..."
                disabled={status === 'submitting'}
              ></textarea>
            </div>

            <div class="form-actions">
              <button type="submit" class="btn" disabled={status === 'submitting'}>
                {status === 'submitting' ? 'Sending Dispatch...' : 'Send Dispatch'}
              </button>
            </div>
          </form>
        {/if}
      </div>
    </div>

    <div class="contact-list">
      <div class="contact-row">
        <span class="contact-row__label">Email</span>
        <MailLink class="contact-row__value" />
        <span class="contact-row__note">Replies within a day or two</span>
      </div>

      <div class="contact-row">
        <span class="contact-row__label">GitHub (org)</span>
        <a class="contact-row__value" href={githubOrgUrl} target="_blank" rel="noopener">
          github.com/qouver
        </a>
      </div>

      <div class="contact-row">
        <span class="contact-row__label">GitHub (maintainer)</span>
        <a class="contact-row__value" href={githubMaintainerUrl} target="_blank" rel="noopener">
          github.com/nferdazel
        </a>
      </div>
    </div>
  </div>
</section>

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

<section class="section container">
  <div class="editorial">
    <div class="editorial__label">Inquiry</div>
    <div>
      <h2 class="h3">Send a dispatch</h2>
      <p class="body mt-2">
        Direct inquiries regarding collaboration, systems architecture, or engineering notes.
      </p>

      {#if status === 'success'}
        <div class="form-alert form-alert--success mt-2" role="status">
          <p class="form-alert__title">Message received.</p>
          <p class="form-alert__body">
            Thank you for reaching out. We will review your inquiry and follow up directly.
          </p>
          <button
            type="button"
            class="btn btn--secondary mt-2"
            onclick={() => (status = 'idle')}
          >
            Send another dispatch
          </button>
        </div>
      {:else}
        <form class="contact-form mt-2" onsubmit={handleSubmit}>
          {#if status === 'error'}
            <div class="form-alert form-alert--error" role="alert">
              <p class="form-alert__title">Failed to send message</p>
              <p class="form-alert__body">{errorMessage || 'Please verify your information and try again.'}</p>
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
            <button
              type="submit"
              class="btn"
              disabled={status === 'submitting'}
            >
              {status === 'submitting' ? 'Sending Dispatch...' : 'Send Dispatch'}
            </button>
          </div>
        </form>
      {/if}
    </div>
  </div>
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

<style>
  .contact-form {
    display: flex;
    flex-direction: column;
    max-width: 68ch;
  }

  .form-row {
    display: grid;
    grid-template-columns: 1fr;
    gap: var(--s-4);
  }

  @media (min-width: 640px) {
    .form-row {
      grid-template-columns: 1fr 1fr;
    }
  }

  .form-field {
    display: flex;
    flex-direction: column;
    gap: var(--s-1);
    margin-bottom: var(--s-4);
  }

  .form-label {
    font-size: var(--step--1);
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--ink-2);
  }

  .form-required {
    color: var(--accent);
  }

  .form-input,
  .form-textarea {
    width: 100%;
    font-family: var(--font-sans);
    font-size: var(--step-0);
    color: var(--ink);
    background: var(--paper-2);
    border: 1px solid var(--rule);
    border-radius: 0;
    padding: var(--s-3) var(--s-4);
    min-height: 44px;
    box-sizing: border-box;
    transition: border-color 0.15s ease;
  }

  .form-input:focus-visible,
  .form-textarea:focus-visible {
    border-color: var(--ink);
    outline: 2px solid var(--accent);
    outline-offset: 1px;
  }

  .form-input:disabled,
  .form-textarea:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .form-textarea {
    resize: vertical;
    min-height: 120px;
    line-height: 1.5;
  }

  .form-actions {
    margin-top: var(--s-2);
  }

  .form-alert {
    border: 2px solid var(--rule);
    padding: var(--s-4);
    margin-bottom: var(--s-5);
    max-width: 68ch;
  }

  .form-alert--error {
    border-color: var(--accent);
    background: rgba(178, 58, 26, 0.08);
  }

  .form-alert--success {
    border-color: #2b7a4b;
    background: rgba(43, 122, 75, 0.08);
  }

  .form-alert__title {
    font-family: var(--font-display);
    font-size: var(--step-1);
    font-weight: 600;
    line-height: 1.2;
    margin-bottom: var(--s-1);
  }

  .form-alert__body {
    color: var(--ink-2);
    font-size: var(--step-0);
    margin: 0;
  }
</style>

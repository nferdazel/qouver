<script lang="ts">
  import { contactEmail } from '$lib/site.js';

  interface Props {
    class?: string;
    label?: string;
  }

  let { class: className = '', label }: Props = $props();

  // Cloudflare Email Address Obfuscation rewrites every mailto: in the HTML the
  // build emits into /cdn-cgi/l/email-protection, which 404s on a static host
  // and takes the address away from no-JS readers. So no mailto: is emitted:
  // the address lives in attributes and is joined on click, and without JS the
  // link still goes to /contact, where the address is printed as text.
  const [user, domain] = contactEmail.split('@');
</script>

<a
  href="/contact"
  class={className}
  data-mail-user={user}
  data-mail-domain={domain}
  onclick={(event) => {
    event.preventDefault();
    window.location.href = `mailto:${user}@${domain}`;
  }}>{label ?? contactEmail}</a>

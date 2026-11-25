<script lang="ts">
  import type { ProjectStatus } from '$lib/data/projects.js';

  interface Props {
    status: ProjectStatus;
  }

  let { status }: Props = $props();

  // Yellow is the operating state, grey is the archive. "Backend" stays a word
  // on the chip so it reads as a scope, not as a weaker "Live".
  const tone = $derived(status === 'Archived' ? 'chip--off' : 'chip--on');
</script>

<span class="chip {tone}">{status}</span>

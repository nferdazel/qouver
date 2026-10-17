<script lang="ts">
  import type { ProjectStatus } from '$lib/data/projects.js';

  interface Props {
    status: ProjectStatus;
  }

  let { status }: Props = $props();

  const modifier = $derived.by(() => {
    switch (status) {
      case 'Live':
        return 'badge--live project-card__status--live';
      case 'Backend':
        return 'badge--bronze';
      case 'Archived':
        return 'project-card__status--archived';
    }
  });
</script>

<span class="badge project-card__status {modifier}">
  <span class="status-dot {status === 'Live' ? 'status-dot--live' : ''}"></span>
  {status}
</span>

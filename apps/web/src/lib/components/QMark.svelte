<script lang="ts">
  interface Props {
    size?: string;
    class?: string;
    accentDot?: boolean;
  }

  let { size = '32', class: className = '', accentDot = false }: Props = $props();
</script>

<svg
  class={className}
  width={size}
  height={size}
  viewBox="0 0 64 64"
  fill="none"
  aria-hidden="true"
>
  <circle
    class="q-mark__ring"
    cx="27"
    cy="27"
    r="17.5"
    stroke="currentColor"
    stroke-width="4.5"
  />
  <path
    class="q-mark__tail"
    d="M 37.5 37.5 C 44 44, 49 48, 54 51.5"
    stroke="currentColor"
    stroke-width="4.5"
    stroke-linecap="round"
  />
  <circle
    class="q-mark__dot {accentDot ? 'q-mark__dot--accent' : ''}"
    cx="27"
    cy="27"
    r="4.2"
    fill="currentColor"
  />
</svg>

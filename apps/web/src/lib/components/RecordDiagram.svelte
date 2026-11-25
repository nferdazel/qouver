<script lang="ts">
  import type { CaseDiagram } from '$lib/data/projects.js';

  interface Props {
    diagram: CaseDiagram;
    index: number;
  }

  let { diagram, index }: Props = $props();

  const TOP = 8;
  const STEP = 120;
  const BOX_H = 88;
  const titleId = $derived(`figure-${index}-title`);
  const descId = $derived(`figure-${index}-desc`);

  // Labels are HTML-free SVG text at 14/15px, the floor of the type scale, so
  // the figure never needs a smaller font than the page.
  const rowY = (i: number) => TOP + i * STEP;
</script>

<figure class="figure">
  <svg viewBox="0 0 700 400" role="img" aria-labelledby="{titleId} {descId}">
    <title id={titleId}>{diagram.title}</title>
    <desc id={descId}>{diagram.description}</desc>
    <g font-family="Public Sans, sans-serif" fill="#0A0A0A">
      {#each diagram.blocks as block, i}
        <rect
          x="120"
          y={rowY(i)}
          width="460"
          height={BOX_H}
          fill={block.accent ? '#FFD400' : '#FFFFFF'}
          stroke="#0A0A0A"
          stroke-width="2"
        />
        <text x="140" y={rowY(i) + 26} font-size="14" letter-spacing="1.2" font-weight="600"
          >{block.label.toUpperCase()}</text
        >
        <text x="140" y={rowY(i) + 50} font-size="15" font-weight="600">{block.value}</text>
        <text x="140" y={rowY(i) + 72} font-size="14" fill="#4A4A4A">{block.note}</text>

        {#if i < diagram.blocks.length - 1}
          <line
            x1="350"
            y1={rowY(i) + BOX_H}
            x2="350"
            y2={rowY(i) + BOX_H + 24}
            stroke="#0A0A0A"
            stroke-width="2"
          />
          <path d="M350 124l-6-8h12z" transform="translate(0,{i * STEP})" fill="#0A0A0A" />
          <text x="362" y={rowY(i) + BOX_H + 20} font-size="14" font-weight="600" fill="#4A4A4A"
            >{diagram.connectors[i]}</text
          >
        {/if}
      {/each}

      {#if diagram.footer}
        <rect x="120" y="352" width="460" height="1" fill="#0A0A0A" />
        <text x="120" y="378" font-size="14" letter-spacing="1.2" font-weight="600"
          >{diagram.footer.toUpperCase()}</text
        >
      {/if}
    </g>
  </svg>
  <figcaption><b>Figure {index}.</b> {diagram.caption}</figcaption>
</figure>

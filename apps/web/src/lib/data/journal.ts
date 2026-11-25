export interface JournalArticle {
  slug: string;
  title: string;
  date: string;
  readTime: string;
  category: string;
  summary: string;
  paragraphs: string[];
  quote?: string;
  codeSnippet?: string;
}

// Reading time is derived, not typed by hand: a hand-written "6 min read" next
// to three short paragraphs is a claim the page cannot back up. 200 words a
// minute, rounded to the nearest minute, never below one.
export function readingTime(paragraphs: string[]): string {
  const words = paragraphs.join(' ').trim().split(/\s+/).filter(Boolean).length;
  return `${Math.max(1, Math.round(words / 200))} min read`;
}

type ArticleInput = Omit<JournalArticle, 'readTime'>;

// The slug `zero-js-static-jaspr` is kept because it is a live URL. The article
// under it describes what this site actually does: prerendered HTML plus a
// hydration bundle, not a zero-JavaScript Jaspr build, which never existed here.
const articles: ArticleInput[] = [
  {
    slug: 'authoritative-go-simulations',
    title: 'Authoritative World Tick Simulation Engines in Go',
    date: '2026-09-08',
    category: 'Architecture',
    summary:
      "Why client-side calculated state always diverges, and how we built Skyward's deterministic server tick engine in standard library Go.",
    quote:
      'Moving simulation authority entirely to backend workers guarantees 100% fair play, zero cheat vectors, and instant state synchronization across clients.',
    codeSnippet: `// World tick loop in Go
func (s *TickEngine) Start(ctx context.Context) {
    ticker := time.NewTicker(s.interval)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case t := <-ticker.C:
            s.processTickWindow(t)
        }
    }
}`,
    paragraphs: [
      'When building Skyward, an airline tycoon simulation, the initial temptation was to calculate flight progression and market yields on the client. But client-side calculation suffers from device clock tampering, battery drain during offline calculation, and state divergence across mobile and desktop apps.',
      'To solve this, we moved all mathematical authority to a deterministic backend tick worker in Go. The Flutter client acts purely as a reactive viewer rendering server snapshots.',
      'By decoupling calculation from presentation, the world tick loop runs continuously in production on PostgreSQL transactions without relying on any client JavaScript or client state hacks.',
    ],
  },
  {
    slug: 'zero-js-static-jaspr',
    title: 'Static First: How This Site Ships HTML Before JavaScript',
    date: '2026-08-18',
    category: 'Web Craft',
    summary:
      'Every route is prerendered at build time with adapter-static, then hydrated by a small SvelteKit bundle. What that buys, and what it costs.',
    quote:
      'Prerendering removes the server from the request path. It does not remove the browser from the page, and pretending otherwise is the part that fails.',
    codeSnippet: `// apps/web/src/routes/+layout.ts
export const prerender = true;
export const ssr = true;
export const trailingSlash = 'never';`,
    paragraphs: [
      'This site is built with SvelteKit and adapter-static. Every route is rendered to HTML at build time, and Caddy serves that tree as plain files: no web server renders a page at request time, and there is no loader state to wait for before the text arrives.',
      'What ships alongside the HTML is honest to measure. A home page load fetches about twenty module scripts, roughly 55 KiB gzipped and 119 KiB decoded. An article page is about 50 KiB gzipped. Those bytes buy client-side navigation, the contact form, and the mail link, and they are fetched after the HTML has already painted.',
      'The trade-off is worth naming. With JavaScript blocked, the text, the links and the case studies still work, because the markup is real. The contact form does not, because it posts through fetch. That is the boundary this site accepts: content readable without script, interaction requiring it.',
    ],
  },
  {
    slug: 'systems-prospector-manifesto',
    title: 'The Systems Prospector: Finding Latent Value in Latent Problems',
    date: '2026-08-15',
    category: 'Philosophy',
    summary:
      'Valuable systems hide in overlooked places: sports scoring, compliance documents, and simulation loops. Building for endurance over hype.',
    quote:
      'Something has value that others walk past. Find it, understand it, build a system from it, and write down what you learned.',
    paragraphs: [
      'Most software startups focus on saturated consumer markets or AI wrapper trends. But valuable problems often sit in plain sight: a local community needing structured session ratings, a workplace requiring chemical safety compliance, or a simulation engine.',
      'The role of a systems prospector is to notice these gaps, apply rigorous software craft, and build independent tools that stand up over time.',
      'Projects may evolve or integrate, but the commitment to independent building and open knowledge remains.',
    ],
  },
];

export const journalArticles: JournalArticle[] = articles.map((article) => ({
  ...article,
  readTime: readingTime(article.paragraphs),
}));

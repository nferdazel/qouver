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

export const journalArticles: JournalArticle[] = [
  {
    slug: 'authoritative-go-simulations',
    title: 'Authoritative World Tick Simulation Engines in Go',
    date: '2026-09-08',
    readTime: '6 min read',
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
    title: 'Zero-JS Static Web: Why We Rebuilt Qouver with Jaspr',
    date: '2026-08-18',
    readTime: '4 min read',
    category: 'Web Craft',
    summary:
      'Migrating from heavy SPA frameworks to Jaspr static mode: a 0-JS runtime, pre-rendered HTML, and server-baked SEO.',
    quote:
      'A corporate home page does not need 3MB of hydration scripts to render text and images. Pure static HTML delivers instant paint and zero fragile dependencies.',
    codeSnippet: `// Server prerendering in Jaspr static mode
void main() {
  runApp(Document(
    title: 'Qouver',
    head: [/* static SEO baked here */],
    body: App(),
  ));
}`,
    paragraphs: [
      'In August 2026, we audited our web stack. Many modern sites ship megabytes of client JavaScript just to present static editorial text and project catalogues.',
      'By migrating to Jaspr in static mode, every route is prerendered to pure HTML at build time. There is no client bundle, no hydration delay, and zero client JS execution.',
      'The result is a site with no client JavaScript bundle at all: pre-rendered HTML served directly via Caddy, with self-hosted fonts and images making up the rest of the payload.',
    ],
  },
  {
    slug: 'systems-prospector-manifesto',
    title: 'The Systems Prospector: Finding Latent Value in Latent Problems',
    date: '2026-08-15',
    readTime: '5 min read',
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

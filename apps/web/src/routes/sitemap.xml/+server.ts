import { projects } from '$lib/data/projects.js';
import { journalArticles } from '$lib/data/journal.js';
import { siteUrl } from '$lib/site.js';

export const prerender = true;

interface Entry {
  path: string;
  lastmod?: string;
  priority: string;
}

export function GET() {
  const entries: Entry[] = [
    { path: '/', priority: '1.0' },
    { path: '/projects', priority: '0.9' },
    ...projects
      .filter((project) => project.caseStudy)
      .map((project) => ({ path: `/projects/${project.slug}`, priority: '0.8' })),
    { path: '/journal', priority: '0.8' },
    ...journalArticles.map((article) => ({
      path: `/journal/${article.slug}`,
      lastmod: article.date,
      priority: '0.7',
    })),
    { path: '/about', priority: '0.6' },
    { path: '/contact', priority: '0.6' },
  ];

  const urls = entries
    .map((entry) => {
      const lastmod = entry.lastmod
        ? `\n    <lastmod>${entry.lastmod}</lastmod>`
        : '';
      return `  <url>\n    <loc>${siteUrl}${entry.path}</loc>${lastmod}\n    <priority>${entry.priority}</priority>\n  </url>`;
    })
    .join('\n');

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>
`;

  return new Response(xml, {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}

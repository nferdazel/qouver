import { error } from '@sveltejs/kit';
import { journalArticles } from '$lib/data/journal.js';
import type { EntryGenerator, PageLoad } from './$types.js';

export const entries: EntryGenerator = () => {
  return journalArticles.map((a) => ({ slug: a.slug }));
};

export const load: PageLoad = ({ params }) => {
  const article = journalArticles.find((a) => a.slug === params.slug);
  if (!article) {
    throw error(404, 'Article not found');
  }
  return { article };
};

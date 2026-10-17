import { error } from '@sveltejs/kit';
import { projects } from '$lib/data/projects.js';
import type { EntryGenerator, PageLoad } from './$types.js';

export const entries: EntryGenerator = () => {
  return projects.map((p) => ({ slug: p.slug }));
};

export const load: PageLoad = ({ params }) => {
  const project = projects.find((p) => p.slug === params.slug);
  if (!project) {
    throw error(404, 'Case study not found');
  }
  return { project };
};

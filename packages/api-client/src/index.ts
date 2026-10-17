import createClient from 'openapi-fetch';
import type { paths } from './generated/schema.js';

export type { paths } from './generated/schema.js';
export type { components } from './generated/schema.js';

export function createQouverClient(baseUrl = '') {
  return createClient<paths>({ baseUrl });
}

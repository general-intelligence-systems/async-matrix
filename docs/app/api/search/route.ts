import { source } from '@/lib/source';
import { createFromSource } from 'fumadocs-core/search/server';

// `staticGET` exports the whole search index as one static document, which the browser downloads
// and queries itself, because a static export has no server to answer a query.
export const revalidate = false;

export const { staticGET: GET } = createFromSource(source);

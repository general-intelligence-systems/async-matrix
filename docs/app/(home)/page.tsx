import Link from 'next/link';
import { appName, docsRoute, gitConfig } from '@/lib/shared';

export default function HomePage() {
  return (
    <main className="flex flex-col justify-center text-center flex-1 gap-6 px-4">
      <div>
        <h1 className="text-3xl font-bold mb-3">{appName}</h1>
        <p className="text-fd-muted-foreground max-w-xl mx-auto">
          A Ruby client for the Matrix client-server API, built on async-rest: logging in,
          enumerating and creating rooms, reading room state and members, sending events, paging
          through a timeline, and running a sync loop.
        </p>
      </div>
      <div className="flex gap-4 justify-center">
        <Link href={docsRoute} className="font-medium underline">
          Read the documentation
        </Link>
        <Link
          href={`https://github.com/${gitConfig.user}/${gitConfig.repo}`}
          className="font-medium underline"
        >
          Source on GitHub
        </Link>
      </div>
    </main>
  );
}

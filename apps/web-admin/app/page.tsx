'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { loadSession } from '../lib/storage';

export default function HomePage() {
  const router = useRouter();

  useEffect(() => {
    const session = loadSession();
    router.replace(session ? '/dashboard' : '/login');
  }, [router]);

  return (
    <div className="card">
      <p>Weiterleitung...</p>
    </div>
  );
}

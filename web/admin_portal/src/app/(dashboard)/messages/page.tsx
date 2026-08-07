import MessagesClient from './MessagesClient';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Support Messages | OnlyGigz Admin',
  description: 'Manage support messages from musicians and organizers',
};

export default function MessagesPage() {
  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-white">Support Messages</h1>
        <p className="text-gray-400 text-sm mt-1">Chat in real-time with users seeking help.</p>
      </div>
      <MessagesClient />
    </div>
  );
}

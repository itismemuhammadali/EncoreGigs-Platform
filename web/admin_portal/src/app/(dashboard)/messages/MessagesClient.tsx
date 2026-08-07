'use client';

import { useState, useEffect, useRef } from 'react';
import { BASE_URL } from '@/lib/api';

interface ChatInfo {
  userId: string;
  userType: string;
  userName: string;
  isFeatured: boolean;
  lastMessage: string;
  lastMessageTime: string;
  unreadByAdmin: boolean;
  profileImageUrl?: string;
  email?: string;
  phone?: string;
  location?: string;
  bio?: string;
  instruments?: string[];
  genres?: string[];
  experience?: number;
  rating?: number;
  orgName?: string;
  type?: string;
  address?: string;
  website?: string;
}

interface Message {
  id: string;
  text: string;
  senderId: string;
  senderType: string;
  timestamp: string;
}

// Default Avatar Component with Icon
const DefaultAvatar = ({ userType, size = 'md' }: { userType: string; size?: 'sm' | 'md' | 'lg' }) => {
  const sizeClasses = {
    sm: 'w-10 h-10 text-lg font-bold',
    md: 'w-12 h-12 text-xl font-bold',
    lg: 'w-16 h-16 text-3xl font-bold',
  };

  const bgColor = userType === 'musician' ? 'bg-blue-600' : 'bg-purple-600';
  const letter = userType === 'musician' ? 'M' : 'O';

  return (
    <div className={`${sizeClasses[size]} ${bgColor} rounded-full flex items-center justify-center flex-shrink-0 text-white`}>
      {letter}
    </div>
  );
};

// Profile Picture Component (with fallback to default avatar)
const ProfilePicture = ({
  src,
  userType,
  size = 'md',
  onClick,
}: {
  src?: string;
  userType: string;
  size?: 'sm' | 'md' | 'lg';
  onClick?: () => void;
}) => {
  const sizeClasses = {
    sm: 'w-10 h-10',
    md: 'w-12 h-12',
    lg: 'w-16 h-16',
  };

  if (!src) {
    return <DefaultAvatar userType={userType} size={size} />;
  }

  return (
    <img
      src={src}
      alt="Profile"
      onClick={onClick}
      className={`${sizeClasses[size]} rounded-full object-cover bg-gray-700 flex-shrink-0 ${
        onClick ? 'cursor-pointer hover:opacity-80 transition-opacity' : ''
      }`}
    />
  );
};

export default function MessagesClient() {
  const [chats, setChats] = useState<ChatInfo[]>([]);
  const [activeChat, setActiveChat] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [filter, setFilter] = useState('All');
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [imageModalOpen, setImageModalOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);
  const [emojiPickerOpen, setEmojiPickerOpen] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const activeChatData = chats.find(c => c.userId === activeChat);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const fetchChats = async () => {
    try {
      const userTypeParam = filter === 'All' ? '' : filter.toLowerCase();
      const unreadParam = unreadOnly ? 'true' : 'false';
      const res = await fetch(`${BASE_URL}/support/chats?user_type=${userTypeParam}&unread_only=${unreadParam}`);
      if (res.ok) {
        const data = await res.json();
        setChats(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const fetchMessages = async (userId: string) => {
    try {
      const res = await fetch(`${BASE_URL}/support/chats/${userId}/messages`);
      if (res.ok) {
        const data = await res.json();
        setMessages(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    fetchChats();
    const interval = setInterval(fetchChats, 5000);
    return () => clearInterval(interval);
  }, [filter, unreadOnly]);

  useEffect(() => {
    if (activeChat) {
      fetchMessages(activeChat);
      const interval = setInterval(() => fetchMessages(activeChat), 3000);
      return () => clearInterval(interval);
    }
  }, [activeChat]);

  const sendMessage = async () => {
    if (!inputText.trim() || !activeChat) return;

    try {
      await fetch(`${BASE_URL}/support/chats/${activeChat}/messages`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: inputText }),
      });
      setInputText('');
      fetchMessages(activeChat);
    } catch (e) {
      console.error(e);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // TODO: Upload file to Firebase Storage and send as message
      console.log('File selected:', file.name);
    }
  };

  const insertEmoji = (emoji: string) => {
    setInputText(inputText + emoji);
    setEmojiPickerOpen(false);
  };

  // Extended emoji collection organized by category
  const commonEmojis = [
    // Smileys & Emotion
    '😀', '😂', '😍', '😘', '😎', '🤔', '😢', '😡',
    '😠', '😤', '😞', '😖', '😣', '😫', '🤨', '😒',
    '😤', '😠', '😠', '🤬', '😈', '👿', '💀', '☠️',
    
    // Hearts & Love
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💔', '💕', '💞', '💓', '💗', '💖', '💘',
    
    // Gestures & Celebration
    '👍', '👎', '👏', '🙌', '👏', '🙏', '💪', '🤝',
    '🎉', '🎊', '🎈', '🎁', '🏆', '⭐', '✨', '🔥',
    
    // Music & Entertainment
    '🎵', '🎶', '🎤', '🎧', '🎸', '🎹', '🎺', '🥁',
    '🎭', '🎬', '🎪', '🎨', '🎯', '🎲', '🃏', '🎰',
    
    // Common
    '💯', '✅', '❌', '⚠️', '⏰', '⏱️', '⌛', '📱',
    '💻', '🔔', '📢', '📣', '📞', '📧', '💬', '📝',
  ];

  // Image Viewer Modal
  const ImageModal = () => (
    <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50" onClick={() => setImageModalOpen(false)}>
      <div className="relative max-w-2xl max-h-[80vh]" onClick={(e) => e.stopPropagation()}>
        <button
          onClick={() => setImageModalOpen(false)}
          className="absolute -top-10 right-0 text-white text-xl hover:text-gray-300"
        >
          ✕
        </button>
        {activeChatData?.profileImageUrl ? (
          <img
            src={activeChatData.profileImageUrl}
            alt="Profile"
            className="w-full h-full object-cover rounded-lg"
          />
        ) : (
          <div className="w-96 h-96 rounded-lg flex items-center justify-center" style={{
            backgroundColor: activeChatData?.userType === 'musician' ? '#2563eb' : '#9333ea'
          }}>
            <div className="text-9xl font-bold text-white">
              {activeChatData?.userType === 'musician' ? 'M' : 'O'}
            </div>
          </div>
        )}
      </div>
    </div>
  );

  // Profile Detail Modal
  const ProfileModal = () => (
    <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50" onClick={() => setProfileModalOpen(false)}>
      <div className="bg-gray-900 border border-gray-800 rounded-xl max-w-md w-full max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="p-6 space-y-4">
          {/* Header */}
          <div className="flex justify-between items-start mb-4">
            <h2 className="text-2xl font-bold text-white">{activeChatData?.userName}</h2>
            <button
              onClick={() => setProfileModalOpen(false)}
              className="text-gray-400 hover:text-white text-xl"
            >
              ✕
            </button>
          </div>

          {/* Profile Image or Default Avatar */}
          {activeChatData?.profileImageUrl ? (
            <img
              src={activeChatData.profileImageUrl}
              alt="Profile"
              className="w-full h-48 object-cover rounded-lg"
            />
          ) : (
            <div className="w-full h-48 rounded-lg flex items-center justify-center" style={{
              backgroundColor: activeChatData?.userType === 'musician' ? '#2563eb' : '#9333ea'
            }}>
              <div className="text-6xl font-bold text-white">
                {activeChatData?.userType === 'musician' ? 'M' : 'O'}
              </div>
            </div>
          )}

          {/* Role Badge */}
          <div className="flex gap-2">
            <span className={`px-3 py-1 rounded-full text-sm font-bold text-white ${
              activeChatData?.userType === 'musician' ? 'bg-blue-600' : 'bg-purple-600'
            }`}>
              {activeChatData?.userType === 'musician' ? '🎵 Musician' : '🎭 Organizer'}
            </span>
          </div>

          {/* Common Fields */}
          {activeChatData?.email && (
            <div className="border-t border-gray-700 pt-4">
              <p className="text-gray-400 text-sm">Email</p>
              <p className="text-white">{activeChatData.email}</p>
            </div>
          )}

          {activeChatData?.phone && (
            <div className="border-t border-gray-700 pt-4">
              <p className="text-gray-400 text-sm">Phone</p>
              <p className="text-white">{activeChatData.phone}</p>
            </div>
          )}

          {activeChatData?.location && (
            <div className="border-t border-gray-700 pt-4">
              <p className="text-gray-400 text-sm">Location</p>
              <p className="text-white">{activeChatData.location}</p>
            </div>
          )}

          {activeChatData?.bio && (
            <div className="border-t border-gray-700 pt-4">
              <p className="text-gray-400 text-sm">About</p>
              <p className="text-white text-sm">{activeChatData.bio}</p>
            </div>
          )}

          {/* Musician-specific Fields */}
          {activeChatData?.userType === 'musician' && (
            <>
              {activeChatData?.instruments && activeChatData.instruments.length > 0 && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Instruments</p>
                  <div className="flex flex-wrap gap-2 mt-2">
                    {activeChatData.instruments.map((inst, idx) => (
                      <span key={idx} className="px-2 py-1 bg-blue-900 text-blue-100 rounded text-xs">
                        {inst}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {activeChatData?.genres && activeChatData.genres.length > 0 && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Genres</p>
                  <div className="flex flex-wrap gap-2 mt-2">
                    {activeChatData.genres.map((genre, idx) => (
                      <span key={idx} className="px-2 py-1 bg-blue-900 text-blue-100 rounded text-xs">
                        {genre}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {activeChatData?.experience !== undefined && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Experience</p>
                  <p className="text-white">{activeChatData.experience} years</p>
                </div>
              )}

              {activeChatData?.rating !== undefined && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Rating</p>
                  <p className="text-white">⭐ {activeChatData.rating.toFixed(1)}/5.0</p>
                </div>
              )}
            </>
          )}

          {/* Organizer-specific Fields */}
          {activeChatData?.userType === 'organizer' && (
            <>
              {activeChatData?.orgName && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Organization</p>
                  <p className="text-white">{activeChatData.orgName}</p>
                </div>
              )}

              {activeChatData?.type && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Type</p>
                  <p className="text-white">{activeChatData.type}</p>
                </div>
              )}

              {activeChatData?.address && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Address</p>
                  <p className="text-white text-sm">{activeChatData.address}</p>
                </div>
              )}

              {activeChatData?.website && (
                <div className="border-t border-gray-700 pt-4">
                  <p className="text-gray-400 text-sm">Website</p>
                  <a href={activeChatData.website} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300 text-sm">
                    {activeChatData.website}
                  </a>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );

  return (
    <div className="flex h-[calc(100vh-100px)] bg-gray-900 rounded-xl overflow-hidden border border-gray-800">
      {/* Sidebar - Chats List */}
      <div className="w-1/3 border-r border-gray-800 flex flex-col bg-gray-900">
        <div className="p-4 border-b border-gray-800">
          <h2 className="text-xl font-bold text-white mb-4">Support Chats</h2>
          <div className="flex gap-2 mb-3">
            {['All', 'Musician', 'Organizer'].map(f => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1 rounded-full text-sm ${
                  filter === f 
                    ? 'bg-[#A1F301] text-black font-semibold' 
                    : 'bg-gray-800 text-gray-400 hover:text-white'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
          <button
            onClick={() => setUnreadOnly(!unreadOnly)}
            className={`px-3 py-1 rounded-full text-sm w-full ${
              unreadOnly 
                ? 'bg-red-600 text-white font-semibold' 
                : 'bg-gray-800 text-gray-400 hover:text-white'
            }`}
          >
            {unreadOnly ? '🔴 Unread Only' : '⚪ All Messages'}
          </button>
        </div>
        <div className="flex-1 overflow-y-auto">
          {chats.length === 0 ? (
            <div className="p-8 text-center text-gray-500">No active chats</div>
          ) : (
            chats.map(chat => (
              <div
                key={chat.userId}
                onClick={() => setActiveChat(chat.userId)}
                className={`p-4 border-b border-gray-800 cursor-pointer hover:bg-gray-800 transition-colors ${
                  activeChat === chat.userId ? 'bg-gray-800 border-l-4 border-l-[#A1F301]' : ''
                }`}
              >
                <div className="flex items-start gap-3 mb-2">
                  {/* Profile Picture with Fallback */}
                  <ProfilePicture src={chat.profileImageUrl} userType={chat.userType} size="sm" />
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex justify-between items-start">
                      <h3 className="font-semibold text-white truncate">
                        {chat.userName}
                        <span className={`ml-2 px-2 py-0.5 rounded text-xs font-bold ${
                          chat.userType === 'musician' 
                            ? 'bg-blue-500 text-white' 
                            : 'bg-purple-500 text-white'
                        }`}>
                          {chat.userType === 'musician' ? 'MUS' : 'ORG'}
                        </span>
                      </h3>
                      <div className="flex items-center gap-2">
                        {chat.unreadByAdmin && (
                          <span className="bg-red-600 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
                            •
                          </span>
                        )}
                      </div>
                    </div>
                    <p className="text-sm text-gray-400 truncate">{chat.lastMessage}</p>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col bg-[#0A0A0F]">
        {activeChat && activeChatData ? (
          <>
            {/* Chat Header with Profile Picture and Name */}
            <div className="p-4 border-b border-gray-800 flex items-center justify-between">
              <div className="flex items-center gap-4">
                {/* Profile Picture - Clickable */}
                <div onClick={() => activeChatData.profileImageUrl && setImageModalOpen(true)} className={activeChatData.profileImageUrl ? 'cursor-pointer' : ''}>
                  <ProfilePicture src={activeChatData.profileImageUrl} userType={activeChatData.userType} size="md" />
                </div>
                
                {/* Name and Details */}
                <div>
                  {/* Name - Clickable */}
                  <h2
                    onClick={() => setProfileModalOpen(true)}
                    className="text-lg font-semibold text-white cursor-pointer hover:text-[#A1F301] transition-colors"
                  >
                    {activeChatData.userName}
                    <span className={`ml-2 px-2 py-0.5 rounded text-xs font-bold ${
                      activeChatData.userType === 'musician'
                        ? 'bg-blue-500 text-white'
                        : 'bg-purple-500 text-white'
                    }`}>
                      {activeChatData.userType === 'musician' ? 'MUS' : 'ORG'}
                    </span>
                  </h2>
                  <span className="text-sm text-gray-500 capitalize">
                    Click name for details • {activeChatData.userType}
                  </span>
                </div>
              </div>
            </div>
            
            {/* Messages Area */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 flex flex-col">
              {messages.map(msg => {
                const isAdmin = msg.senderType === 'admin';
                return (
                  <div key={msg.id} className={`flex ${isAdmin ? 'justify-end' : 'justify-start'}`}>
                    <div className={`max-w-[70%] rounded-xl p-3 ${
                      isAdmin 
                        ? 'bg-[#A1F301] text-black rounded-tr-sm' 
                        : 'bg-gray-800 text-white rounded-tl-sm'
                    }`}>
                      <p className="text-sm">{msg.text}</p>
                      <p className={`text-xs mt-1 text-right ${isAdmin ? 'text-gray-700' : 'text-gray-400'}`}>
                        {new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </div>
                );
              })}
              <div ref={messagesEndRef} />
            </div>

            {/* Input Area */}
            <div className="p-4 border-t border-gray-800 bg-gray-900">
              <div className="flex items-center gap-2">
                {/* File Input (hidden) */}
                <input
                  ref={fileInputRef}
                  type="file"
                  onChange={handleFileSelect}
                  className="hidden"
                  accept="image/*,.pdf,.doc,.docx"
                />

                {/* File Picker Button */}
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="text-gray-400 hover:text-white transition-colors p-2"
                  title="Attach file"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                  </svg>
                </button>

                {/* Text Input */}
                <input
                  type="text"
                  value={inputText}
                  onChange={(e) => setInputText(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && sendMessage()}
                  placeholder="Type your message..."
                  className="flex-1 bg-gray-800 border border-gray-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-[#A1F301]"
                />

                {/* Emoji Picker Button */}
                <div className="relative">
                  <button
                    onClick={() => setEmojiPickerOpen(!emojiPickerOpen)}
                    className="text-gray-400 hover:text-white transition-colors p-2"
                    title="Add emoji"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </button>

                  {/* Emoji Picker Dropdown */}
                  {emojiPickerOpen && (
                    <div className="absolute bottom-12 right-0 bg-gray-800 border border-gray-700 rounded-lg p-3 z-50 grid grid-cols-8 gap-1 w-72 max-h-48 overflow-y-auto">
                      {commonEmojis.map((emoji, idx) => (
                        <button
                          key={idx}
                          onClick={() => insertEmoji(emoji)}
                          className="text-xl hover:bg-gray-700 rounded p-1 transition-colors"
                        >
                          {emoji}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {/* Send Button with Rotated Icon */}
                <button
                  onClick={sendMessage}
                  className="bg-[#A1F301] text-black p-2 rounded-lg hover:bg-[#8ee000] transition-colors"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    style={{ transform: 'rotate(60deg)' }}
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                  </svg>
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-500">
            Select a chat to start messaging
          </div>
        )}
      </div>

      {/* Modals */}
      {imageModalOpen && <ImageModal />}
      {profileModalOpen && <ProfileModal />}
    </div>
  );
}

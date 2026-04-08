import { useEffect, useState, useRef } from 'react';
import { db } from '../firebase';
import { 
  collection, 
  query, 
  orderBy, 
  onSnapshot, 
  addDoc, 
  updateDoc, 
  doc,
  serverTimestamp,
  setDoc,
  increment
} from 'firebase/firestore';
import { 
  MessageCircle, 
  User, 
  Clock, 
  Send, 
  Search,
  MoreVertical,
  X,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';

function SupportInbox() {
  const [sessions, setSessions] = useState([]);
  const [selectedSession, setSelectedSession] = useState(null);
  const [messages, setMessages] = useState([]);
  const [reply, setReply] = useState('');
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const chatEndRef = useRef(null);

  // Load Sessions
  useEffect(() => {
    const q = query(collection(db, 'admin_chats'), orderBy('lastMessageTime', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setSessions(list);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  // Load Messages for Selected Session
  useEffect(() => {
    if (!selectedSession) return;

    const q = query(
      collection(db, 'admin_chats', selectedSession.id, 'messages'), 
      orderBy('timestamp', 'asc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setMessages(list);
      
      // Auto-scroll to bottom
      setTimeout(() => chatEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    });

    // Mark as read when opening
    updateDoc(doc(db, 'admin_chats', selectedSession.id), { unreadCount: 0 });

    return () => unsubscribe();
  }, [selectedSession]);

  const handleSendReply = async (e) => {
    e.preventDefault();
    if (!reply.trim() || !selectedSession) return;

    const text = reply.trim();
    setReply('');

    try {
      const chatRef = doc(db, 'admin_chats', selectedSession.id);
      const msgRef = collection(chatRef, 'messages');

      await addDoc(msgRef, {
        text,
        senderId: 'admin',
        senderName: 'Admin Support',
        timestamp: serverTimestamp(),
        isUser: false,
      });

      await updateDoc(chatRef, {
        lastMessage: text,
        lastMessageTime: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
    } catch (error) {
      console.error("Error sending reply:", error);
    }
  };

  const filteredSessions = sessions.filter(s => 
    s.studentName?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    s.studentEmail?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div style={{ display: 'flex', height: 'calc(100vh - 160px)', gap: '1.5rem' }}>
      {/* Sessions List */}
      <div className="glass" style={{ width: '320px', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <div style={{ padding: '1.25rem', borderBottom: '1px solid var(--border)' }}>
          <h3 style={{ fontSize: '1.125rem', fontWeight: 900, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <MessageCircle size={20} color="var(--primary)" /> Active Chats
          </h3>
          <div style={{ position: 'relative' }}>
            <Search size={14} style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted)' }} />
            <input
              className="input-field"
              style={{ paddingLeft: '2.2rem', paddingRight: '0.75rem', paddingVertical: '0.5rem', width: '100%', fontSize: '0.8rem' }}
              placeholder="Search students..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>

        <div style={{ flex: 1, overflowY: 'auto' }}>
          {loading ? (
            <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted)' }}>Synchronizing inbox...</div>
          ) : filteredSessions.length === 0 ? (
            <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted)', fontSize: '0.875rem' }}>No active conversations found.</div>
          ) : (
            filteredSessions.map(session => (
              <div 
                key={session.id}
                onClick={() => setSelectedSession(session)}
                style={{
                  padding: '1rem 1.25rem',
                  borderBottom: '1px solid var(--border)',
                  cursor: 'pointer',
                  background: selectedSession?.id === session.id ? 'rgba(255,255,255,0.05)' : 'transparent',
                  transition: '0.2s',
                  display: 'flex',
                  gap: '1rem',
                  alignItems: 'center',
                  position: 'relative'
                }}
              >
                <div style={{ 
                  width: '44px', 
                  height: '44px', 
                  borderRadius: '50%', 
                  background: 'var(--primary-light)', 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center',
                  fontWeight: 900,
                  fontSize: '1rem',
                  color: 'white',
                  border: '1px solid var(--border)'
                }}>
                  {session.studentName?.charAt(0).toUpperCase()}
                </div>
                <div style={{ flex: 1, overflow: 'hidden' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ fontWeight: 800, fontSize: '0.9rem', color: 'white', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{session.studentName}</div>
                    {session.unreadCount > 0 && (
                      <div style={{ background: 'var(--accent)', color: 'white', fontSize: '0.7rem', fontWeight: 900, padding: '2px 6px', borderRadius: '999px' }}>{session.unreadCount}</div>
                    )}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{session.lastMessage || 'Start writing...'}</div>
                </div>
                {selectedSession?.id === session.id && (
                  <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '4px', background: 'var(--primary)' }} />
                )}
              </div>
            ))
          )}
        </div>
      </div>

      {/* Chat Window */}
      <div className="glass" style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {selectedSession ? (
          <>
            {/* Header */}
            <div style={{ padding: '1.25rem', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'rgba(2, 6, 23, 0.4)' }}>
              <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                <div style={{ width: '44px', height: '44px', borderRadius: '50%', background: 'var(--primary-light)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 900, fontSize: '1rem', color: 'white' }}>
                  {selectedSession.studentName?.charAt(0).toUpperCase()}
                </div>
                <div>
                  <div style={{ fontWeight: 900, fontSize: '1.1rem' }}>{selectedSession.studentName}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 600 }}>{selectedSession.studentEmail}</div>
                </div>
              </div>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button className="btn-ghost" style={{ padding: '0.5rem' }}><AlertCircle size={18} /></button>
                <button className="btn-ghost" style={{ padding: '0.5rem' }} onClick={() => setSelectedSession(null)}><X size={18} /></button>
              </div>
            </div>

            {/* Messages Area */}
            <div style={{ flex: 1, overflowY: 'auto', padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem', background: 'rgba(255,255,255,0.01)' }}>
              {messages.length === 0 ? (
                <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted)', fontSize: '0.875rem' }}>History record synchronized. Start your response.</div>
              ) : (
                messages.map(msg => (
                  <div 
                    key={msg.id}
                    style={{
                      alignSelf: msg.isUser ? 'flex-start' : 'flex-end',
                      maxWidth: '75%',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: msg.isUser ? 'flex-start' : 'flex-end',
                    }}
                  >
                    <div style={{
                      padding: '0.75rem 1rem',
                      borderRadius: '1.25rem',
                      borderBottomLeftRadius: msg.isUser ? '0' : '1.25rem',
                      borderBottomRightRadius: msg.isUser ? '1.25rem' : '0',
                      background: msg.isUser ? 'var(--card)' : 'var(--primary)',
                      color: 'white',
                      fontSize: '0.925rem',
                      lineHeight: 1.5,
                      border: msg.isUser ? '1px solid var(--border)' : 'none',
                      boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
                    }}>
                      {msg.text}
                    </div>
                    <div style={{ fontSize: '0.65rem', color: 'var(--muted)', marginTop: '4px', fontWeight: 600 }}>
                      {msg.timestamp?.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </div>
                  </div>
                ))
              )}
              <div ref={chatEndRef} />
            </div>

            {/* Input Area */}
            <form 
              onSubmit={handleSendReply}
              style={{ padding: '1.25rem', borderTop: '1px solid var(--border)', display: 'flex', gap: '0.75rem', background: 'rgba(2, 6, 23, 0.4)' }}
            >
              <input
                className="input-field"
                style={{ flex: 1, padding: '0.85rem 1.25rem' }}
                placeholder="Type your response to student..."
                value={reply}
                onChange={(e) => setReply(e.target.value)}
              />
              <button 
                type="submit" 
                className="btn-primary" 
                disabled={!reply.trim()}
                style={{ padding: '0.85rem 1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}
              >
                <Send size={18} /> Send Reply
              </button>
            </form>
          </>
        ) : (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'var(--muted)', textAlign: 'center', padding: '2rem' }}>
            <div style={{ background: 'rgba(139, 92, 246, 0.1)', padding: '2rem', borderRadius: '50%', marginBottom: '1.5rem' }}>
              <MessageCircle size={48} color="var(--primary)" />
            </div>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 900, color: 'white', marginBottom: '0.5rem' }}>Select a Conversation</h3>
            <p style={{ maxWidth: '300px' }}>Select a conversation from the left to start responding to student inquiries and support requests.</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default SupportInbox;

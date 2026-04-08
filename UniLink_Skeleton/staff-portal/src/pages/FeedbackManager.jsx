import { useEffect, useState } from 'react';
import { db } from '../firebase';
import { 
  collection, 
  query, 
  orderBy, 
  onSnapshot, 
  updateDoc, 
  doc,
  deleteDoc
} from 'firebase/firestore';
import { 
  MessageSquare, 
  User, 
  Clock, 
  CheckCircle2, 
  Trash2,
  Filter,
  Search,
  MessageCircle
} from 'lucide-react';

function FeedbackManager() {
  const [feedbacks, setFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all'); // all, new, resolved
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'feedbacks'), orderBy('timestamp', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate() || new Date()
      }));
      setFeedbacks(list);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const handleStatusChange = async (id, newStatus) => {
    try {
      await updateDoc(doc(db, 'feedbacks', id), { status: newStatus });
    } catch (error) {
      console.error("Error updating status:", error);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this feedback record?")) return;
    try {
      await deleteDoc(doc(db, 'feedbacks', id));
    } catch (error) {
      console.error("Error deleting feedback:", error);
    }
  };

  const filteredFeedbacks = feedbacks.filter(fb => {
    const matchesFilter = filter === 'all' || fb.status === filter;
    const matchesSearch = fb.studentEmail?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                         fb.studentName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         fb.text?.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const stats = {
    total: feedbacks.length,
    new: feedbacks.filter(f => f.status === 'new').length,
    resolved: feedbacks.filter(f => f.status === 'resolved').length
  };

  return (
    <div style={{ maxWidth: 1200, margin: '0 auto' }}>
      <header style={{ marginBottom: '2rem' }}>
        <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary)', letterSpacing: '0.1em', marginBottom: '0.5rem' }}>VOICE OF THE STUDENT</div>
        <h2 style={{ fontSize: '2rem', fontWeight: 900 }}>Student Feedback</h2>
        <p style={{ color: 'var(--muted)' }}>Monitor and resolve student suggestions, complaints, and compliments.</p>
      </header>

      {/* Stats Summary */}
      <div className="stats-grid" style={{ marginBottom: '2rem' }}>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(139, 92, 246, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <MessageSquare size={24} color="var(--primary)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Total Feedbacks</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.total}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(245, 158, 11, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <Clock size={24} color="var(--accent)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Unresolved</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.new}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(20, 184, 166, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <CheckCircle2 size={24} color="var(--secondary)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Resolved</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.resolved}</div>
          </div>
        </div>
      </div>

      {/* Controls */}
      <div className="glass" style={{ padding: '1.25rem', marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          {['all', 'new', 'resolved'].map(t => (
            <button
              key={t}
              onClick={() => setFilter(t)}
              style={{
                padding: '0.5rem 1rem',
                borderRadius: '0.75rem',
                border: '1px solid var(--border)',
                background: filter === t ? 'var(--primary)' : 'transparent',
                color: filter === t ? 'white' : 'var(--muted)',
                fontWeight: 700,
                fontSize: '0.8rem',
                cursor: 'pointer',
                textTransform: 'capitalize'
              }}
            >
              {t}
            </button>
          ))}
        </div>
        <div style={{ position: 'relative', width: '300px' }}>
          <Search size={16} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted)' }} />
          <input
            className="input-field"
            style={{ paddingLeft: '2.5rem', width: '100%' }}
            placeholder="Search email, name or text..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {/* List */}
      <div style={{ display: 'grid', gap: '1rem' }}>
        {loading ? (
          <div className="card glass" style={{ textAlign: 'center', padding: '3rem' }}>Retrieving student voices...</div>
        ) : filteredFeedbacks.length === 0 ? (
          <div className="card glass" style={{ textAlign: 'center', padding: '4rem', color: 'var(--muted)' }}>
            <MessageCircle size={48} style={{ opacity: 0.2, marginBottom: '1rem' }} />
            <div style={{ fontSize: '1.25rem', fontWeight: 900, color: 'white' }}>Silence is Golden</div>
            <div>No feedbacks found matching your criteria.</div>
          </div>
        ) : (
          filteredFeedbacks.map(fb => (
            <div key={fb.id} className="card glass" style={{ padding: '1.5rem', borderLeft: `4px solid ${fb.status === 'resolved' ? 'var(--secondary)' : 'var(--accent)'}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' }}>
                    <div style={{ background: 'var(--card)', padding: '0.5rem', borderRadius: '0.5rem', border: '1px solid var(--border)' }}>
                      <User size={16} color="var(--primary)" />
                    </div>
                    <div>
                      <div style={{ fontWeight: 800, fontSize: '1rem' }}>{fb.studentName}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 600 }}>{fb.studentEmail} • {fb.timestamp.toLocaleString()}</div>
                    </div>
                    <div className={`badge ${fb.status === 'resolved' ? 'badge-success' : 'badge-warning'}`} style={{ marginLeft: 'auto' }}>
                      {fb.status?.toUpperCase()}
                    </div>
                  </div>
                  <p style={{ fontSize: '1rem', lineHeight: 1.6, color: '#e2e8f0', margin: '0 0 1.5rem 0', background: 'rgba(255,255,255,0.02)', padding: '1rem', borderRadius: '1rem', border: '1px solid var(--border)' }}>
                    "{fb.text}"
                  </p>
                  <div style={{ display: 'flex', gap: '1rem', justifyContent: 'flex-end' }}>
                    {fb.status === 'new' && (
                      <button 
                        onClick={() => handleStatusChange(fb.id, 'resolved')}
                        className="btn-ghost" 
                        style={{ color: 'var(--secondary)', fontSize: '0.8rem', padding: '0.5rem 1rem' }}
                      >
                        <CheckCircle2 size={16} /> Mark as Resolved
                      </button>
                    )}
                    {fb.status === 'resolved' && (
                      <button 
                        onClick={() => handleStatusChange(fb.id, 'new')}
                        className="btn-ghost" 
                        style={{ color: 'var(--accent)', fontSize: '0.8rem', padding: '0.5rem 1rem' }}
                      >
                        <Clock size={16} /> Mark as Pending
                      </button>
                    )}
                    <button 
                      onClick={() => handleDelete(fb.id)}
                      className="btn-ghost" 
                      style={{ color: '#f87171', fontSize: '0.8rem', padding: '0.5rem 1rem' }}
                    >
                      <Trash2 size={16} /> Delete Record
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default FeedbackManager;

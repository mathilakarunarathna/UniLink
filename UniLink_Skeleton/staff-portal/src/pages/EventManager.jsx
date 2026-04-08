import { useState, useEffect } from 'react';
import { 
  Calendar, 
  MapPin, 
  Tag, 
  Plus, 
  Edit2, 
  Trash2, 
  Search, 
  Filter, 
  X, 
  Image as ImageIcon,
  Ticket,
  Users,
  Clock,
  AlertCircle,
  CheckCircle2
} from 'lucide-react';
import { db } from '../firebase';
import { 
  collection, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  onSnapshot, 
  query, 
  orderBy, 
  serverTimestamp 
} from 'firebase/firestore';

function EventManager() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterCategory, setFilterCategory] = useState('all');
  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [currentEventId, setCurrentEventId] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    date: '',
    time: '',
    venue: '',
    category: 'Workshop',
    imageUrl: '',
    ticketPrice: 0,
    totalTickets: 100
  });

  const categories = ['Workshop', 'Seminar', 'Concert', 'Sports', 'Cultural', 'Other'];

  useEffect(() => {
    const q = query(collection(db, 'events'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setEvents(list);
      setLoading(false);
    }, (err) => {
      console.error("Firestore error:", err);
      setError("Failed to sync with event database.");
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'ticketPrice' || name === 'totalTickets' ? Number(value) : value
    }));
  };

  const resetForm = () => {
    setFormData({
      title: '',
      description: '',
      date: '',
      time: '',
      venue: '',
      category: 'Workshop',
      imageUrl: '',
      ticketPrice: 0,
      totalTickets: 100
    });
    setIsEditing(false);
    setCurrentEventId(null);
    setError('');
  };

  const handleOpenAddModal = () => {
    resetForm();
    setShowModal(true);
  };

  const handleOpenEditModal = (event) => {
    setFormData({
      title: event.title || '',
      description: event.description || '',
      date: event.date || '',
      time: event.time || '',
      venue: event.venue || '',
      category: event.category || 'Workshop',
      imageUrl: event.imageUrl || '',
      ticketPrice: event.ticketPrice || 0,
      totalTickets: event.totalTickets || 0
    });
    setIsEditing(true);
    setCurrentEventId(event.id);
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setBusy(true);
    setError('');
    setSuccess('');

    try {
      const payload = {
        ...formData,
        availableTickets: isEditing ? formData.totalTickets : formData.totalTickets, // Simple logic for now
        updatedAt: serverTimestamp()
      };

      if (isEditing) {
        await updateDoc(doc(db, 'events', currentEventId), payload);
        setSuccess('Event updated successfully!');
      } else {
        await addDoc(collection(db, 'events'), {
          ...payload,
          createdAt: serverTimestamp(),
          active: true
        });
        setSuccess('Event published successfully!');
      }
      setShowModal(false);
      resetForm();
    } catch (err) {
      console.error("Submit error:", err);
      setError("Failed to save event. Please check your connection.");
    } finally {
      setBusy(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this event? This action cannot be undone.")) return;
    
    try {
      await deleteDoc(doc(db, 'events', id));
      setSuccess('Event removed.');
    } catch (err) {
      setError("Failed to delete event.");
    }
  };

  const filteredEvents = events.filter(ev => {
    const matchesSearch = ev.title?.toLowerCase().includes(searchQuery.toLowerCase()) || 
                         ev.venue?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = filterCategory === 'all' || ev.category === filterCategory;
    return matchesSearch && matchesCategory;
  });

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
      {/* Header Section */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '0.5rem' }}>Event Management</h1>
          <p style={{ color: 'var(--muted)', fontWeight: 600 }}>Create and manage campus-wide events and ticketing.</p>
        </div>
        <button className="btn-primary" onClick={handleOpenAddModal} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Plus size={20} /> Create New Event
        </button>
      </div>

      {/* Filters & Search */}
      <div className="glass" style={{ padding: '1.5rem', marginBottom: '2rem', display: 'flex', gap: '1.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ flex: 1, minWidth: '300px', position: 'relative' }}>
          <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted)' }} />
          <input 
            className="input-field" 
            style={{ paddingLeft: '3rem' }} 
            placeholder="Search events by title or venue..." 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <Filter size={18} color="var(--muted)" />
          <select 
            className="input-field" 
            style={{ width: '180px' }}
            value={filterCategory}
            onChange={(e) => setFilterCategory(e.target.value)}
          >
            <option value="all">All Categories</option>
            {categories.map(cat => <option key={cat} value={cat}>{cat}</option>)}
          </select>
        </div>
      </div>

      {error && <div className="badge badge-danger" style={{ marginBottom: '1.5rem' }}>{error}</div>}
      {success && <div className="badge badge-success" style={{ marginBottom: '1.5rem' }}>{success}</div>}

      {/* Event Grid */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '4rem' }}>Loading events...</div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem' }}>
          {filteredEvents.length > 0 ? (
            filteredEvents.map(event => (
              <div key={event.id} className="card glass" style={{ padding: 0, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
                <div style={{ height: '180px', background: `url(${event.imageUrl || 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?q=80&w=1470&auto=format&fit=crop'}) center/cover` }}>
                  <div style={{ padding: '0.75rem', display: 'flex', justifyContent: 'flex-end' }}>
                     <span className="badge" style={{ background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(10px)', border: '1px solid rgba(255,255,255,0.1)' }}>
                        {event.category}
                     </span>
                  </div>
                </div>
                
                <div style={{ padding: '1.5rem', flex: 1 }}>
                  <h3 style={{ margin: '0 0 0.5rem', fontSize: '1.25rem', fontWeight: 800 }}>{event.title}</h3>
                  <div style={{ display: 'grid', gap: '0.5rem', color: 'var(--muted)', fontSize: '0.85rem', fontWeight: 600, marginBottom: '1rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <Calendar size={14} color="var(--primary)" /> {event.date} at {event.time}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <MapPin size={14} color="var(--primary)" /> {event.venue}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <Ticket size={14} color="var(--primary)" /> LKR {event.ticketPrice.toLocaleString()} • {event.totalTickets} Capacity
                    </div>
                  </div>
                  <p style={{ fontSize: '0.9rem', color: '#94a3b8', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', marginBottom: '1.5rem' }}>
                    {event.description}
                  </p>
                  
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto' }}>
                    <button className="btn-ghost" onClick={() => handleOpenEditModal(event)} style={{ padding: '0.5rem 1rem' }}>
                      <Edit2 size={16} /> Edit
                    </button>
                    <button className="btn-ghost" onClick={() => handleDelete(event.id)} style={{ padding: '0.5rem 1rem', color: '#f43f5e' }}>
                      <Trash2 size={16} /> Delete
                    </button>
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div style={{ gridColumn: '1 / -1', padding: '4rem', textAlign: 'center', color: 'var(--muted)' }} className="glass">
              <Calendar size={48} style={{ opacity: 0.2, marginBottom: '1rem' }} />
              <p style={{ fontWeight: 700 }}>No events found. Start by creating one!</p>
            </div>
          )}
        </div>
      )}

      {/* Add/Edit Modal */}
      {showModal && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(2, 6, 23, 0.8)', backdropFilter: 'blur(8px)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
          <div className="glass" style={{ width: '100%', maxWidth: '600px', maxHeight: '90vh', overflowY: 'auto', borderRadius: '1.5rem', border: '1px solid var(--border)', padding: '2rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h2 style={{ margin: 0, fontWeight: 900 }}>{isEditing ? 'Edit Event' : 'Create New Event'}</h2>
              <button className="btn-ghost" onClick={() => setShowModal(false)} style={{ padding: '0.5rem' }}>
                <X size={24} />
              </button>
            </div>

            <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '1.25rem' }}>
              <div>
                <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>EVENT TITLE</label>
                <input className="input-field" name="title" value={formData.title} onChange={handleInputChange} placeholder="e.g. Annual Tech Symposium" required />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>DATE</label>
                  <input type="date" className="input-field" name="date" value={formData.date} onChange={handleInputChange} required />
                </div>
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>TIME</label>
                  <input type="time" className="input-field" name="time" value={formData.time} onChange={handleInputChange} required />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>VENUE</label>
                <input className="input-field" name="venue" value={formData.venue} onChange={handleInputChange} placeholder="e.g. Main Auditorium" required />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>CATEGORY</label>
                  <select className="input-field" name="category" value={formData.category} onChange={handleInputChange}>
                    {categories.map(cat => <option key={cat} value={cat}>{cat}</option>)}
                  </select>
                </div>
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>POSTER IMAGE URL</label>
                  <input className="input-field" name="imageUrl" value={formData.imageUrl} onChange={handleInputChange} placeholder="https://..." />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>TICKET PRICE (LKR)</label>
                  <input type="number" className="input-field" name="ticketPrice" value={formData.ticketPrice} onChange={handleInputChange} min="0" required />
                </div>
                <div>
                  <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>TOTAL CAPACITY</label>
                  <input type="number" className="input-field" name="totalTickets" value={formData.totalTickets} onChange={handleInputChange} min="1" required />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>DESCRIPTION</label>
                <textarea className="input-field" name="description" value={formData.description} onChange={handleInputChange} style={{ minHeight: '100px', resize: 'vertical', paddingTop: '0.75rem' }} placeholder="Tell us more about the event..." required />
              </div>

              <button className="btn-primary" type="submit" disabled={busy} style={{ marginTop: '1rem', height: '3.5rem', fontSize: '1rem' }}>
                {busy ? 'Saving...' : isEditing ? 'Update Event' : 'Publish Event'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default EventManager;

import { useEffect, useState, useMemo } from 'react';
import { db } from '../firebase';
import { 
  collection, 
  query, 
  onSnapshot, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  orderBy, 
  serverTimestamp 
} from 'firebase/firestore';
import { 
  BookOpen, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  User, 
  Trash2, 
  Filter,
  Search,
  Calendar,
  Layers,
  CheckCircle,
  AlertCircle
} from 'lucide-react';

function StudyRoomManager() {
  const [bookings, setBookings] = useState([]);
  const [isFetching, setIsFetching] = useState(false);
  const [isUpdating, setIsUpdating] = useState(null); // stores ID of updating booking
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const stats = useMemo(() => {
    return {
      total: bookings.length,
      pending: bookings.filter(b => b.status === 'pending').length,
      confirmed: bookings.filter(b => b.status === 'confirmed').length,
      rejected: bookings.filter(b => b.status === 'rejected').length
    };
  }, [bookings]);

  useEffect(() => {
    setIsFetching(true);
    // Real-time listener for Bookings
    const qBookings = query(collection(db, 'space_bookings'), orderBy('timestamp', 'desc'));
    const unsubscribeBookings = onSnapshot(qBookings, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate() || null
      }));
      setBookings(data);
      setIsFetching(false);
    }, (err) => {
      console.error('Bookings listener error:', err);
      setError('Failed to sync bookings.');
      setIsFetching(false);
    });

    return () => {
      unsubscribeBookings();
    };
  }, []);

  const handleUpdateStatus = async (id, status) => {
    setIsUpdating(id);
    setError('');
    setSuccess('');
    try {
      await updateDoc(doc(db, 'space_bookings', id), { 
        status,
        updatedAt: serverTimestamp()
      });
      setSuccess(`Booking ${status} successfully`);
    } catch (err) {
      console.error('Error updating status:', err);
      setError(`Failed to update booking to ${status}`);
    } finally {
      setIsUpdating(null);
    }
  };

  const handleAddRoom = async (e) => {
    e.preventDefault();
    setIsUpdating('adding');
    try {
      await addDoc(collection(db, 'study_rooms'), {
        ...newRoom,
        capacity: parseInt(newRoom.capacity),
        createdAt: serverTimestamp()
      });
      setSuccess('Room added successfully');
      setNewRoom({ name: '', capacity: 4, facultyId: 'F1', facultyName: 'Library' });
      setIsAddingRoom(false);
    } catch (err) {
      console.error('Add room error:', err);
      setError('Failed to add room');
    } finally {
      setIsUpdating(null);
    }
  };

  const handleDeleteRoom = async (id) => {
    if (!window.confirm('Delete this room asset?')) return;
    setIsUpdating(id);
    try {
      await deleteDoc(doc(db, 'study_rooms', id));
      setSuccess('Room deleted');
    } catch (err) {
      console.error('Delete room error:', err);
      setError('Failed to delete room');
    } finally {
      setIsUpdating(null);
    }
  };

  const handleDeleteBooking = async (id) => {
    if (!window.confirm('Are you sure you want to remove this booking record?')) return;
    setIsUpdating(id);
    try {
      await deleteDoc(doc(db, 'space_bookings', id));
      setSuccess('Booking record deleted');
    } catch (err) {
      setError('Failed to delete record');
    } finally {
      setIsUpdating(null);
    }
  };

  const filteredBookings = bookings.filter(b => {
    const matchesStatus = filterStatus === 'all' || b.status === filterStatus;
    const matchesSearch = 
      b.studentName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.studentId.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.roomName.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  return (
    <div style={{ maxWidth: 1200, margin: '0 auto' }}>
      {/* Top Header */}
      <div style={{ marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '2rem', fontWeight: 900, margin: 0 }}>Study Space Management</h2>
        <p style={{ color: 'var(--muted)', fontWeight: 600 }}>Review and manage student room booking requests</p>
      </div>

      {/* Stats Grid */}
      <div className="stats-grid" style={{ marginBottom: '2rem' }}>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(139, 92, 246, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <Layers size={24} color="var(--primary)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Total Requests</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.total}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(245, 158, 11, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <Clock size={24} color="var(--accent)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Pending</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.pending}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(20, 184, 166, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <CheckCircle size={24} color="var(--secondary)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Confirmed</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.confirmed}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(239, 68, 68, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <AlertCircle size={24} color="#f87171" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Rejected</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.rejected}</div>
          </div>
        </div>
      </div>

      {/* Controls */}
      <div className="glass" style={{ padding: '1.5rem', marginBottom: '2rem', display: 'flex', flexWrap: 'wrap', gap: '1.5rem', alignItems: 'center' }}>
        <div style={{ flex: 1, minWidth: '300px', position: 'relative' }}>
          <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted)' }} />
          <input 
            className="input-field" 
            style={{ paddingLeft: '3rem' }} 
            placeholder="Search by student, ID, or room..." 
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
          />
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <Filter size={18} color="var(--muted)" />
          <select 
            className="input-field" 
            style={{ width: '180px' }}
            value={filterStatus}
            onChange={e => setFilterStatus(e.target.value)}
          >
            <option value="all">All statuses</option>
            <option value="pending">Pending Only</option>
            <option value="confirmed">Confirmed Only</option>
            <option value="rejected">Rejected Only</option>
          </select>
          <button onClick={() => {}} className="btn-ghost" disabled={isFetching}>
            <Clock size={16} className={isFetching ? 'spin' : ''} /> Auto-synced
          </button>
        </div>
      </div>

      {error && <div className="badge badge-danger" style={{ marginBottom: '1.5rem', display: 'inline-flex' }}>{error}</div>}
      {success && <div className="badge badge-success" style={{ marginBottom: '1.5rem', display: 'inline-flex' }}>{success}</div>}

      {/* Bookings List */}
      <div style={{ display: 'grid', gap: '1rem' }}>
        {filteredBookings.length > 0 ? (
          filteredBookings.map((booking) => (
            <div key={booking.id} className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '2rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', flex: 1 }}>
                <div style={{ background: 'rgba(255,255,255,0.03)', padding: '1rem', borderRadius: '1rem', border: '1px solid var(--border)' }}>
                  <BookOpen size={28} color="var(--primary)" />
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.25rem' }}>
                    <h4 style={{ margin: 0, fontSize: '1.125rem', fontWeight: 800 }}>{booking.roomName}</h4>
                    <span className={`badge ${booking.status === 'confirmed' ? 'badge-success' : booking.status === 'pending' ? 'badge-warning' : 'badge-danger'}`}>
                      {booking.status}
                    </span>
                  </div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1.5rem', color: 'var(--muted)', fontSize: '0.875rem', fontWeight: 600 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                      <User size={14} /> {booking.studentName} ({booking.studentId})
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                      <Clock size={14} /> {booking.time}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                      <Calendar size={14} /> {booking.timestamp ? new Date(booking.timestamp).toLocaleDateString() : 'N/A'}
                    </div>
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '0.75rem' }}>
                {booking.status === 'pending' && (
                  <>
                    <button 
                      onClick={() => handleUpdateStatus(booking.id, 'confirmed')}
                      disabled={isUpdating === booking.id}
                      className="btn-ghost"
                      style={{ color: 'var(--secondary)', borderColor: 'rgba(20, 184, 166, 0.3)' }}
                    >
                      <CheckCircle2 size={18} /> Confirm
                    </button>
                    <button 
                      onClick={() => handleUpdateStatus(booking.id, 'rejected')}
                      disabled={isUpdating === booking.id}
                      className="btn-ghost"
                      style={{ color: '#f87171', borderColor: 'rgba(248, 113, 113, 0.3)' }}
                    >
                      <XCircle size={18} /> Reject
                    </button>
                  </>
                )}
                {booking.status !== 'pending' && (
                   <button 
                   onClick={() => handleUpdateStatus(booking.id, 'pending')}
                   disabled={isUpdating === booking.id}
                   className="btn-ghost"
                   style={{ fontSize: '0.75rem' }}
                 >
                   Revert to Pending
                 </button>
                )}
                <button 
                  onClick={() => handleDeleteBooking(booking.id)}
                  disabled={isUpdating === booking.id}
                  className="btn-ghost"
                  style={{ color: 'var(--muted)', padding: '0.5rem' }}
                >
                  <Trash2 size={18} />
                </button>
              </div>
            </div>
          ))
        ) : (
          <div className="glass" style={{ padding: '4rem', textAlign: 'center', color: 'var(--muted)' }}>
            <Search size={48} style={{ marginBottom: '1rem', opacity: 0.2 }} />
            <p style={{ fontWeight: 700 }}>No bookings found matching your criteria.</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default StudyRoomManager;

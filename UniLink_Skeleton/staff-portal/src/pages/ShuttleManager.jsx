
import { useEffect, useState, useMemo } from 'react';
import Modal from 'react-modal';
import { db } from '../firebase';
import {
  collection,
  addDoc,
  getDocs,
  updateDoc,
  deleteDoc,
  doc,
  serverTimestamp,
  query,
  orderBy,
  onSnapshot
} from 'firebase/firestore';
import { getStorage, ref, uploadBytes, getDownloadURL, uploadBytesResumable } from 'firebase/storage';
import { 
  Bus, 
  MapPin, 
  Clock, 
  Phone, 
  User, 
  CheckCircle2, 
  Plus, 
  Edit2, 
  Trash2, 
  Info, 
  Image as ImageIcon,
  TrendingUp,
  Activity,
  AlertTriangle,
  School,
  Users,
  ShieldAlert,
  Zap
} from 'lucide-react';

function ShuttleManager() {
  const [shuttles, setShuttles] = useState([]);
  const [form, setForm] = useState({
    busNumber: '',
    route: '',
    toCampus: '',
    fromCampus: '',
    available: true,
    contact: '',
    maintenance: false,
    driver: '',
    atUniversity: false,
    photoUrl: '',
    notes: '',
    category: 'Non-A/C',
    capacity: 40,
    seatStatus: 'Available',
    emergencyContact: '011 231 2112'
  });
  
  const [photoFile, setPhotoFile] = useState(null);
  const [photoPreview, setPhotoPreview] = useState('');
  
  const [isFetching, setIsFetching] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [uploadProgress, setUploadProgress] = useState(0);
  const [activeStep, setActiveStep] = useState('');
  const [editingId, setEditingId] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedShuttle, setSelectedShuttle] = useState(null);

  // Stats calculation
  const stats = useMemo(() => {
    return {
      total: shuttles.length,
      active: shuttles.filter(s => s.available && !s.maintenance).length,
      maintenance: shuttles.filter(s => s.maintenance).length,
      atUni: shuttles.filter(s => s.atUniversity).length
    };
  }, [shuttles]);

  useEffect(() => {
    setIsFetching(true);
    const q = collection(db, 'shuttles');
    
    // Safety timeout for fetching
    const timeout = setTimeout(() => {
      if (isFetching) setIsFetching(false);
    }, 10000);

    const unsubscribe = onSnapshot(q, (snapshot) => {
      clearTimeout(timeout);
      const fetchedShuttles = snapshot.docs.map(doc => ({ 
        id: doc.id, 
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate?.() || doc.data().createdAt || new Date(0)
      }));
      
      // Sort client-side for immediate results
      fetchedShuttles.sort((a, b) => b.createdAt - a.createdAt);
      setShuttles(fetchedShuttles);
      setIsFetching(false);
    }, (err) => {
      clearTimeout(timeout);
      console.error("Firestore real-time error:", err);
      setError('Real-time sync failed. Check your network.');
      setIsFetching(false);
    });

    return () => {
      unsubscribe();
      clearTimeout(timeout);
    };
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    
    if (!form.busNumber || !form.route || !form.contact) {
      setError('Required fields missing');
      return;
    }

    setIsSubmitting(true);
    setUploadProgress(0);
    try {
      let photoUrl = form.photoUrl;
      let driverPhotoUrl = form.driverPhotoUrl;
      const storage = getStorage();

      const uploadFile = async (file, path, stepLabel) => {
        return new Promise((resolve, reject) => {
          setActiveStep(stepLabel);
          const storageRef = ref(storage, path);
          const uploadTask = uploadBytesResumable(storageRef, file);
          
          uploadTask.on('state_changed', 
            (snapshot) => {
              const prog = Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100);
              setUploadProgress(prog);
            },
            (error) => reject(error),
            async () => {
              const url = await getDownloadURL(uploadTask.snapshot.ref);
              resolve(url);
            }
          );
        });
      };

      // Bus Photo Upload
      if (photoFile) {
        photoUrl = await uploadFile(photoFile, `shuttle_photos/${Date.now()}_bus_${photoFile.name}`, 'Uploading Bus Image');
      }

      setActiveStep('Synchronizing Record');
      const shuttleData = { 
        ...form, 
        photoUrl, 
        updatedAt: new Date().toISOString() 
      };

      if (editingId) {
        await updateDoc(doc(db, 'shuttles', editingId), shuttleData);
        setSuccess('Shuttle network details synchronized');
      } else {
        await addDoc(collection(db, 'shuttles'), {
          ...shuttleData,
          createdAt: serverTimestamp(),
        });
        setSuccess('New shuttle successfully integrated');
      }

      resetForm();
    } catch (e) {
      console.error(e);
      setError('Operation failed. Check storage permissions or connection.');
    } finally {
      setIsSubmitting(false);
      setActiveStep('');
      setUploadProgress(0);
    }
  };

  const resetForm = () => {
    setForm({
      busNumber: '',
      route: '',
      toCampus: '',
      fromCampus: '',
      available: true,
      contact: '',
      maintenance: false,
      driver: '',
      atUniversity: false,
      photoUrl: '',
      notes: '',
      category: 'Non-A/C',
      capacity: 40,
      seatStatus: 'Available',
      emergencyContact: '011 231 2112'
    });
    setPhotoFile(null);
    setPhotoPreview('');
    setEditingId(null);
  };

  const handleEdit = (shuttle) => {
    setForm({
      ...shuttle,
      toCampus: shuttle.toCampus || shuttle.time || '',
      fromCampus: shuttle.fromCampus || '',
      category: shuttle.category || 'Non-A/C',
      capacity: shuttle.capacity || 40,
      seatStatus: shuttle.seatStatus || 'Available',
      emergencyContact: shuttle.emergencyContact || ''
    });
    setPhotoPreview(shuttle.photoUrl || '');
    setPhotoFile(null);
    setEditingId(shuttle.id);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Eject this shuttle from the active network?')) return;
    setIsSubmitting(true);
    try {
      await deleteDoc(doc(db, 'shuttles', id));
      setSuccess('Shuttle removed successfully');
    } catch (e) {
      setError('De-provisioning failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div style={{ maxWidth: 1200, margin: '0 auto' }}>
      {/* Stats Header */}
      <div className="stats-grid">
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(139, 92, 246, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <TrendingUp size={24} color="var(--primary)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Total Fleet</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.total}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(20, 184, 166, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <Activity size={24} color="var(--secondary)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Active Now</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.active}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(245, 158, 11, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <School size={24} color="var(--accent)" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>At University</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.atUni}</div>
          </div>
        </div>
        <div className="glass" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ background: 'rgba(239, 68, 68, 0.2)', padding: '0.75rem', borderRadius: '0.75rem' }}>
            <AlertTriangle size={24} color="#f87171" />
          </div>
          <div>
            <div style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>Maintenance</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{stats.maintenance}</div>
          </div>
        </div>
      </div>

      {/* Form Section */}
      <div className="glass" style={{ padding: '2rem', marginBottom: '2rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 900, marginBottom: '0.25rem' }}>
              {editingId ? 'Modify Provisioning' : 'Register New Fleet Asset'}
            </h2>
            <p style={{ color: 'var(--muted)', fontSize: '0.875rem' }}>Update operational metadata for the NSBM transport network.</p>
          </div>
          {editingId && (
            <button onClick={resetForm} className="btn-ghost" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Plus style={{ transform: 'rotate(45deg)' }} size={16} /> Cancel Operation
            </button>
          )}
        </div>

        <form onSubmit={handleSubmit} className="form-grid">
          <div className="input-group">
            <label><Bus size={14} /> Bus Number / Plate</label>
            <input 
              className="input-field" 
              placeholder="e.g. NB-4521" 
              value={form.busNumber} 
              onChange={e => setForm({...form, busNumber: e.target.value.toUpperCase()})}
              style={{ textTransform: 'uppercase' }}
              required 
            />
          </div>
          <div className="input-group">
            <label><MapPin size={14} /> Primary Route Axis</label>
            <input 
              className="input-field" 
              placeholder="e.g. KOTTAWA - HOMAGAMA" 
              value={form.route} 
              onChange={e => setForm({...form, route: e.target.value.toUpperCase()})}
              style={{ textTransform: 'uppercase' }}
              required 
            />
          </div>
          
          {/* Timing Split */}
          <div className="input-group">
            <label><Clock size={14} /> To Campus (Arrival)</label>
            <input 
              type="time"
              className="input-field" 
              value={form.toCampus} 
              onChange={e => setForm({...form, toCampus: e.target.value})}
            />
          </div>
          <div className="input-group">
            <label><Zap size={14} /> From Campus (Return)</label>
            <input 
              type="time"
              className="input-field" 
              value={form.fromCampus} 
              onChange={e => setForm({...form, fromCampus: e.target.value})}
            />
          </div>

          <div className="input-group">
            <label><User size={14} /> Command Pilot (Driver)</label>
            <input 
              className="input-field" 
              placeholder="Full Name" 
              value={form.driver} 
              onChange={e => setForm({...form, driver: e.target.value})}
            />
          </div>
          <div className="input-group">
            <label><Phone size={14} /> Driver Hotline</label>
            <input 
              className="input-field" 
              placeholder="e.g. 077 123 4567" 
              value={form.contact} 
              onChange={e => setForm({...form, contact: e.target.value})}
              required 
            />
          </div>

          {/* Advanced Metadata */}
          <div className="input-group">
            <label><Zap size={14} /> Fleet Category</label>
            <select 
              className="input-field"
              value={form.category}
              onChange={e => setForm({...form, category: e.target.value})}
            >
              <option value="Non-A/C">Non-A/C Standard</option>
              <option value="A/C">A/C Premium</option>
              <option value="Luxury">Luxury Coach</option>
            </select>
          </div>
          <div className="input-group">
            <label><Users size={14} /> Capacity (Seats)</label>
            <input 
              type="number"
              className="input-field"
              value={form.capacity}
              onChange={e => setForm({...form, capacity: parseInt(e.target.value)})}
            />
          </div>

          <div className="input-group">
            <label><ShieldAlert size={14} /> University Emergency Sync</label>
            <input 
              className="input-field" 
              placeholder="011 231 2112" 
              value={form.emergencyContact} 
              onChange={e => setForm({...form, emergencyContact: e.target.value})}
            />
          </div>
          <div className="input-group">
            <label><Activity size={14} /> Live Seat Status</label>
            <select 
              className="input-field"
              value={form.seatStatus}
              onChange={e => setForm({...form, seatStatus: e.target.value})}
            >
              <option value="Available">Seats Available</option>
              <option value="Filling Fast">Filling Fast</option>
              <option value="Full">At Capacity (Full)</option>
            </select>
          </div>

          {/* Double Photo Upload */}
          <div className="input-group">
            <label><ImageIcon size={14} /> Vehicle Asset Link (External URL)</label>
            <input 
              className="input-field" 
              placeholder="https://images.com/bus.jpg" 
              value={form.photoUrl} 
              onChange={e => { setForm({...form, photoUrl: e.target.value}); setPhotoPreview(e.target.value); }}
            />
          </div>
          <div className="input-group">
            <label><ImageIcon size={14} /> Or Upload Asset File</label>
            <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
              <input type="file" id="bus-photo" hidden accept="image/*" onChange={e => {
                const file = e.target.files[0];
                if(file) { setPhotoFile(file); setPhotoPreview(URL.createObjectURL(file)); }
              }} />
              <label htmlFor="bus-photo" className="btn-ghost" style={{ flex: 1, justifyContent: 'center', height: '100%', display: 'flex', alignItems: 'center' }}>
                {photoFile ? 'Modify Selection' : 'Pick File'}
              </label>
              {photoPreview && <img src={photoPreview} style={{ width: 44, height: 44, borderRadius: '0.75rem', objectFit: 'cover' }} />}
            </div>
          </div>
          
          <div style={{ gridColumn: '1 / span 2', display: 'flex', flexWrap: 'wrap', gap: '1.5rem', padding: '1.25rem', background: 'rgba(255,255,255,0.02)', borderRadius: '1rem', border: '1px solid var(--border)' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', fontSize: '0.875rem', fontWeight: 600 }}>
              <input type="checkbox" checked={form.available} onChange={e => setForm({...form, available: e.target.checked})} />
              Network Availability
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', fontSize: '0.875rem', fontWeight: 600 }}>
              <input type="checkbox" checked={form.atUniversity} onChange={e => setForm({...form, atUniversity: e.target.checked})} />
              University Perimeter Sync
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', fontSize: '0.875rem', fontWeight: 600, color: form.maintenance ? '#f87171' : 'inherit' }}>
              <input type="checkbox" checked={form.maintenance} onChange={e => setForm({...form, maintenance: e.target.checked})} />
              Engage Maintenance Protocol
            </label>
          </div>

          <div style={{ gridColumn: '1 / span 2', display: 'flex', justifyContent: 'flex-end', marginTop: '0.5rem' }}>
            <button type="submit" disabled={isSubmitting} className="btn-primary" style={{ minWidth: '220px' }}>
              {isSubmitting ? (
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {activeStep}: {uploadProgress}%
                </div>
              ) : editingId ? 'Update Network Record' : 'Deploy to Network'}
            </button>
          </div>
        </form>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '0.5rem' }}>
          {isFetching && <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>Retrieving fleet status...</div>}
          {!isFetching && shuttles.length === 0 && (
            <button onClick={() => window.location.reload()} className="btn-ghost" style={{ fontSize: '0.7rem', padding: '4px 8px' }}>
              Force Refresh Feed
            </button>
          )}
        </div>
        {error && <div style={{ marginTop: '1.5rem', display: 'inline-flex' }} className="badge badge-danger">{error}</div>}
        {success && <div style={{ marginTop: '1.5rem', display: 'inline-flex' }} className="badge badge-success">{success}</div>}
      </div>

      {/* Shuttle List Grid */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h3 style={{ fontSize: '1.25rem', fontWeight: 800, margin: 0 }}>Active Fleet Nodes</h3>
        <span style={{ fontSize: '0.875rem', color: 'var(--muted)', fontWeight: 600 }}>{shuttles.length} Asset Records Linked</span>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '1.5rem' }}>
        {shuttles.map((shuttle) => (
          <div key={shuttle.id} className="glass shuttle-card" style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            <div style={{ display: 'flex', gap: '1.25rem' }}>
              <div style={{ position: 'relative' }}>
                {shuttle.photoUrl ? (
                  <img src={shuttle.photoUrl} alt="Bus" style={{ width: 110, height: 85, objectFit: 'cover', borderRadius: '0.75rem' }} />
                ) : (
                  <div style={{ width: 110, height: 85, background: 'rgba(255,255,255,0.03)', borderRadius: '0.75rem', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid var(--border)' }}>
                    <Bus size={32} color="var(--muted)" />
                  </div>
                )}
                {shuttle.atUniversity && (
                  <div style={{ position: 'absolute', top: -6, right: -6, background: 'var(--secondary)', color: 'white', padding: '4px', borderRadius: '50%', border: '2px solid var(--background)', boxShadow: '0 4px 6px rgba(0,0,0,0.2)' }}>
                    <CheckCircle2 size={12} />
                  </div>
                )}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.25rem' }}>
                  <h4 style={{ margin: 0, fontSize: '1.125rem', fontWeight: 800 }}>{shuttle.busNumber}</h4>
                  <div className={`badge ${shuttle.maintenance ? 'badge-danger' : shuttle.available ? 'badge-success' : 'badge-warning'}`}>
                    {shuttle.maintenance ? 'Service' : shuttle.available ? 'Online' : 'Offline'}
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: 'var(--muted)', fontSize: '0.8125rem', fontWeight: 600, marginBottom: '0.5rem' }}>
                  <MapPin size={12} /> {shuttle.route}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: 'var(--foreground)', fontSize: '0.8125rem', fontWeight: 700 }}>
                  <User size={12} color="var(--primary)" />
                  {shuttle.driver || 'No Command Pilot'}
                </div>
              </div>
            </div>

            {/* Quick Stats Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', padding: '1rem', background: 'rgba(255,255,255,0.02)', borderRadius: '0.85rem', border: '1px solid var(--border)' }}>
              <div>
                <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.02em', marginBottom: '0.25rem' }}>Seat Sync</div>
                <div style={{ fontSize: '0.9375rem', fontWeight: 800, color: shuttle.seatStatus === 'Full' ? '#f87171' : 'var(--secondary)' }}>{shuttle.seatStatus || 'Unknown'}</div>
              </div>
              <div>
                <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.02em', marginBottom: '0.25rem' }}>Category</div>
                <div style={{ fontSize: '0.9375rem', fontWeight: 800 }}>{shuttle.category || 'N/A'}</div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', marginTop: 'auto' }}>
              <button onClick={() => { setSelectedShuttle(shuttle); setModalOpen(true); }} className="btn-ghost" style={{ flex: 1, padding: '0.6rem', fontSize: '0.75rem' }}>
                <Info size={14} /> Full Telemetry
              </button>
              <button onClick={() => handleEdit(shuttle)} className="btn-ghost" style={{ padding: '0.6rem', color: 'var(--primary)', borderColor: 'rgba(139,92,246,0.3)' }}>
                <Edit2 size={16} />
              </button>
              <button onClick={() => handleDelete(shuttle.id)} className="btn-ghost" style={{ padding: '0.6rem', color: '#f87171', borderColor: 'rgba(248,113,113,0.3)' }}>
                <Trash2 size={16} />
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Details Modal */}
      <Modal 
        isOpen={modalOpen} 
        onRequestClose={() => setModalOpen(false)} 
        ariaHideApp={false}
        style={{
          overlay: { background: 'rgba(2, 6, 23, 0.85)', backdropFilter: 'blur(8px)', zIndex: 1000 },
          content: { 
            maxWidth: 520, margin: '6rem auto auto', borderRadius: '1.75rem', padding: 0, 
            background: 'var(--background)', border: '1px solid var(--card-border)', color: 'white',
            inset: 'unset', position: 'relative', overflow: 'hidden'
          }
        }}
      >
        {selectedShuttle && (
          <div>
            <div style={{ height: 220, position: 'relative' }}>
              {selectedShuttle.photoUrl ? (
                <img src={selectedShuttle.photoUrl} alt="Bus" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              ) : (
                <div style={{ width: '100%', height: '100%', background: 'rgba(255,255,255,0.03)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Bus size={64} color="var(--muted)" />
                </div>
              )}
              <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, transparent 40%, var(--background))' }} />
              <div style={{ position: 'absolute', bottom: '1.5rem', left: '1.5rem' }}>
                <h2 style={{ fontSize: '2rem', fontWeight: 900, margin: 0, letterSpacing: '-0.02em' }}>{selectedShuttle.busNumber}</h2>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.5rem' }}>
                  <div className="badge badge-info">{selectedShuttle.route}</div>
                  <div className="badge badge-accent">{selectedShuttle.category}</div>
                </div>
              </div>
            </div>
            
            <div style={{ padding: '2rem' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginBottom: '2rem' }}>
                <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                  <div style={{ background: 'var(--card-border)', padding: '10px', borderRadius: '1rem' }}>
                    <User size={24} color="var(--primary)" />
                  </div>
                  <div>
                    <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.25rem' }}>Command Pilot</div>
                    <div style={{ fontWeight: 800, fontSize: '1rem' }}>{selectedShuttle.driver || 'Unassigned'}</div>
                    <div style={{ fontSize: '0.875rem', color: 'var(--secondary)', fontWeight: 700 }}>{selectedShuttle.contact}</div>
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Timeline Split</div>
                  <div style={{ fontWeight: 800, fontSize: '0.875rem' }}>To Campus: {selectedShuttle.toCampus || 'TBD'}</div>
                  <div style={{ fontWeight: 800, fontSize: '0.875rem' }}>From Campus: {selectedShuttle.fromCampus || 'TBD'}</div>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginBottom: '2rem' }}>
                <div>
                  <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Emergency Sync</div>
                  <div style={{ fontWeight: 800, color: '#f87171' }}>{selectedShuttle.emergencyContact || 'Counter Hotline'}</div>
                </div>
                <div>
                  <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Loading Factor</div>
                  <div style={{ fontWeight: 800 }}>{selectedShuttle.seatStatus} ({selectedShuttle.capacity} Seats)</div>
                </div>
              </div>

              <div style={{ marginBottom: '2rem' }}>
                <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.75rem' }}>Network Health</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem' }}>
                  <div className={`badge ${selectedShuttle.available ? 'badge-success' : 'badge-danger'}`}>
                    {selectedShuttle.available ? 'Ready' : 'Suspended'}
                  </div>
                  <div className={`badge ${selectedShuttle.atUniversity ? 'badge-info' : 'badge-warning'}`}>
                    {selectedShuttle.atUniversity ? 'On-Site (Uni)' : 'In Transit'}
                  </div>
                </div>
              </div>

              {selectedShuttle.notes && (
                <div style={{ marginBottom: '2rem', padding: '1.25rem', background: 'rgba(255,255,255,0.02)', borderRadius: '1rem', border: '1px solid var(--border)' }}>
                  <div style={{ fontSize: '0.6875rem', color: 'var(--muted)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Mission Remarks</div>
                  <p style={{ fontSize: '0.875rem', margin: 0, lineHeight: 1.6, color: '#cbd5e1' }}>{selectedShuttle.notes}</p>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '1rem', borderTop: '1px solid var(--border)' }}>
                <div style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 500 }}>
                  Last sync: {selectedShuttle.updatedAt ? new Date(selectedShuttle.updatedAt).toLocaleString() : 'Just Now'}
                </div>
                <button onClick={() => setModalOpen(false)} className="btn-primary" style={{ padding: '0.6rem 1.5rem' }}>Close Telemetry</button>
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

export default ShuttleManager;

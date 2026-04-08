import { useState, useEffect } from 'react';
import CafeteriaManager from './CafeteriaManager';
import ShuttleManager from './ShuttleManager';
import StudyRoomManager from './StudyRoomManager';
import EventManager from './EventManager';
import FeedbackManager from './FeedbackManager';
import SupportInbox from './SupportInbox';
import { Routes, Route, Link, useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';
import { 
  Users, 
  Newspaper, 
  Activity, 
  LogOut, 
  BarChart3, 
  Utensils, 
  Car,
  ShieldAlert,
  Send,
  Plus,
  RefreshCcw,
  CheckCircle2,
  Clock,
  Calendar,
  BookOpen,
  MessageSquare,
  MessageCircle,
  ClipboardList
} from 'lucide-react';
import { auth, db } from '../firebase';
import { 
  collection, 
  getDoc,
  getDocs, 
  addDoc, 
  updateDoc, 
  deleteDoc,
  setDoc,
  doc, 
  onSnapshot, 
  query, 
  orderBy,
  Timestamp,
  serverTimestamp,
  where,
  limit,
  increment,
} from 'firebase/firestore';

function Dashboard() {
  const user = JSON.parse(localStorage.getItem('user'));
  const navigate = useNavigate();
  const location = useLocation();
  const [isSetupChecking, setIsSetupChecking] = useState(true);
  const [showCafeSetup, setShowCafeSetup] = useState(false);
  const [cafeteriaShopName, setCafeteriaShopName] = useState('');
  const [setupBusy, setSetupBusy] = useState(false);
  const [setupError, setSetupError] = useState('');

  const normalizedRole = String(user?.role || '').trim().toLowerCase();
  const isCafeteriaManager = normalizedRole === 'cafeteria_manager';

  useEffect(() => {
    let mounted = true;

    const checkCafeteriaSetup = async () => {
      if (!isCafeteriaManager || !user?.uid) {
        if (mounted) {
          setShowCafeSetup(false);
          setIsSetupChecking(false);
        }
        return;
      }

      try {
        const profileByUid = await getDoc(doc(db, 'users', user.uid));
        let profileData = profileByUid.exists() ? profileByUid.data() : null;

        if (!profileData && user?.email) {
          const byEmail = await getDocs(
            query(collection(db, 'users'), where('email', '==', String(user.email).trim().toLowerCase()), limit(1))
          );
          if (!byEmail.empty) {
            profileData = byEmail.docs[0].data();
          }
        }

        const existingShopName = String(
          profileData?.cafeteriaShopName ||
          profileData?.shopName ||
          profileData?.cafeteriaProfile?.shopName ||
          ''
        ).trim();

        if (!mounted) return;
        setCafeteriaShopName(existingShopName);
        setShowCafeSetup(!existingShopName);
      } catch (error) {
        if (!mounted) return;
        setSetupError('Could not check cafeteria setup status. Please try again.');
        setShowCafeSetup(true);
      } finally {
        if (mounted) setIsSetupChecking(false);
      }
    };

    checkCafeteriaSetup();

    return () => {
      mounted = false;
    };
  }, [isCafeteriaManager, user?.uid, user?.email]);

  const handleLogout = async () => {
    try {
      await auth.signOut();
    } finally {
      localStorage.removeItem('user');
      navigate('/login', { replace: true });
    }
  };

  const handleCompleteCafeteriaSetup = async (e) => {
    e.preventDefault();
    setSetupError('');

    const normalizedShopName = String(cafeteriaShopName || '').trim();
    if (!normalizedShopName) {
      setSetupError('Please enter your cafeteria shop name.');
      return;
    }

    if (!user?.uid) {
      setSetupError('Missing user session. Please log in again.');
      return;
    }

    setSetupBusy(true);
    try {
      const payload = {
        uid: user.uid,
        email: user.email || '',
        role: 'cafeteria_manager',
        cafeteriaShopName: normalizedShopName,
        cafeteriaSetupCompleted: true,
        cafeteriaSetupAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      await setDoc(doc(db, 'users', user.uid), payload, { merge: true });

      const normalizedEmail = String(user.email || '').trim().toLowerCase();
      if (normalizedEmail) {
        const existingShop = await getDocs(
          query(collection(db, 'cafeteria_shops'), where('shopEmail', '==', normalizedEmail), limit(1))
        );

        const shopPayload = {
          shopName: normalizedShopName,
          shopEmail: normalizedEmail,
          ownerUid: user.uid,
          isActive: true,
          updatedAt: serverTimestamp(),
        };

        if (!existingShop.empty) {
          await updateDoc(doc(db, 'cafeteria_shops', existingShop.docs[0].id), shopPayload);
        } else {
          await addDoc(collection(db, 'cafeteria_shops'), {
            ...shopPayload,
            createdAt: serverTimestamp(),
          });
        }
      }

      const nextUser = {
        ...user,
        role: 'cafeteria_manager',
        cafeteriaShopName: normalizedShopName,
      };
      localStorage.setItem('user', JSON.stringify(nextUser));
      setShowCafeSetup(false);
      navigate('/dashboard/orders', { replace: true });
    } catch (error) {
      setSetupError('Failed to save setup. Please try again.');
    } finally {
      setSetupBusy(false);
    }
  };

  if (isSetupChecking) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#020617' }}>
        <div className="glass" style={{ borderRadius: '1rem', border: '1px solid var(--border)', padding: '1.25rem 1.5rem', color: '#cbd5e1', fontWeight: 700 }}>
          Checking profile setup...
        </div>
      </div>
    );
  }

  if (showCafeSetup) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#020617', padding: '1rem' }}>
        <div className="glass" style={{ width: '100%', maxWidth: '560px', borderRadius: '1.2rem', border: '1px solid var(--border)', padding: '1.5rem' }}>
          <p style={{ margin: 0, color: '#94a3b8', fontWeight: 800, fontSize: '0.78rem', letterSpacing: '0.08em' }}>CAFETERIA FIRST-TIME SETUP</p>
          <h2 style={{ margin: '0.45rem 0 0', fontWeight: 900 }}>Complete Your Shop Profile</h2>
          <p style={{ marginTop: '0.6rem', color: 'var(--muted)' }}>Add your cafeteria shop name to continue to orders and operations.</p>

          <form onSubmit={handleCompleteCafeteriaSetup} style={{ marginTop: '1rem', display: 'grid', gap: '0.85rem' }}>
            <div>
              <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>SHOP NAME</label>
              <input
                className="input-field"
                style={{ paddingLeft: '1rem' }}
                value={cafeteriaShopName}
                onChange={(event) => setCafeteriaShopName(event.target.value)}
                placeholder="e.g. UniLink Central Cafeteria"
                required
              />
            </div>

            {setupError && (
              <div style={{ color: '#f43f5e', fontWeight: 700, fontSize: '0.85rem' }}>{setupError}</div>
            )}

            <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.7rem', flexWrap: 'wrap' }}>
              <button
                type="button"
                onClick={handleLogout}
                style={{ padding: '0.65rem 0.95rem', borderRadius: '0.7rem', border: '1px solid var(--border)', background: 'transparent', color: '#cbd5e1', fontWeight: 700, cursor: 'pointer' }}
              >
                Logout
              </button>
              <button
                className="btn-primary"
                type="submit"
                disabled={setupBusy}
                style={{ minWidth: '220px', justifySelf: 'end' }}
              >
                {setupBusy ? 'Saving Setup...' : 'Complete Setup'}
              </button>
            </div>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', height: '100vh', background: '#0f172a' }}>
      {/* Sidebar */}
      <div style={{ width: '280px', borderRight: '1px solid var(--border)', padding: '2rem', display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '3rem' }}>
          <div style={{ background: 'linear-gradient(135deg, #8b5cf6, #14b8a6)', width: '36px', height: '36px', borderRadius: '0.75rem', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <BarChart3 color="white" size={20} />
          </div>
          <span style={{ fontWeight: 900, fontSize: '1.25rem' }}>UniLink Portal</span>
        </div>

        <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          <SidebarLink to="/dashboard" icon={<BarChart3 size={20} />} label="Overview" active={location.pathname === '/dashboard'} />
          
          {user.role === 'admin' && (
            <>
              <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', margin: '1.5rem 0 0.75rem', letterSpacing: '0.1em' }}>ADMINISTRATION</div>
              <SidebarLink to="/dashboard/users" icon={<Users size={20} />} label="User Registry" active={location.pathname === '/dashboard/users'} />
              <SidebarLink to="/dashboard/news" icon={<Newspaper size={20} />} label="Campus News" active={location.pathname === '/dashboard/news'} />
              <SidebarLink to="/dashboard/study-rooms" icon={<BookOpen size={20} />} label="Study Rooms" active={location.pathname === '/dashboard/study-rooms'} />
              <SidebarLink to="/dashboard/feedback" icon={<ClipboardList size={20} />} label="Student Feedback" active={location.pathname === '/dashboard/feedback'} />
              <SidebarLink to="/dashboard/support" icon={<MessageCircle size={20} />} label="Live Support" active={location.pathname === '/dashboard/support'} />
            </>
          )}

          {(user.role === 'admin' || user.role === 'security') && (
            <>
              <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', margin: '1.5rem 0 0.75rem', letterSpacing: '0.1em' }}>SECURITY & ACCESS</div>
              <SidebarLink to="/dashboard/parking" icon={<Car size={20} />} label="Parking Control" active={location.pathname === '/dashboard/parking'} />
              {user.role === 'admin' && (
                <SidebarLink to="/dashboard/lost-found" icon={<ShieldAlert size={20} />} label="Lost & Found" active={location.pathname === '/dashboard/lost-found'} />
              )}
            </>
          )}

          {user.role === 'cafeteria_manager' && (
            <>
              <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', margin: '1.5rem 0 0.75rem', letterSpacing: '0.1em' }}>CAFETERIA OPS</div>
              <SidebarLink to="/dashboard/cafeteria" icon={<Utensils size={20} />} label="Branch Manager" active={location.pathname === '/dashboard/cafeteria'} />
            </>
          )}

          {(user.role === 'admin' || user.role === 'transport_manager') && (
            <>
              <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', margin: '1.5rem 0 0.75rem', letterSpacing: '0.1em' }}>TRANSPORT OPS</div>
              <SidebarLink to="/dashboard/shuttles" icon={<Clock size={20} />} label="Shuttle Management" active={location.pathname === '/dashboard/shuttles'} />
            </>
          )}

          {user.role === 'admin' && (
            <>
              <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted)', margin: '1.5rem 0 0.75rem', letterSpacing: '0.1em' }}>EVENTS & PROMO</div>
              <SidebarLink to="/dashboard/events" icon={<Calendar size={20} />} label="Event Management" active={location.pathname === '/dashboard/events'} />
            </>
          )}
        </nav>

        <button 
          onClick={handleLogout}
          style={{ padding: '0.75rem', borderRadius: '0.75rem', border: '1px solid var(--border)', background: 'transparent', color: '#f43f5e', display: 'flex', alignItems: 'center', gap: '0.75rem', fontWeight: 700, cursor: 'pointer', transition: '0.2s' }}
        >
          <LogOut size={20} /> Logout
        </button>
      </div>

      {/* Main Content */}
      <div style={{ flex: 1, padding: '2rem', overflowY: 'auto' }}>
        <header style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 900 }}>Welcome, {user.name}</h2>
          </div>
        </header>

        <Routes>
          <Route path="/" element={<Overview user={user} />} />
          <Route path="/users" element={<UserRegistry />} />
          <Route path="/news" element={<AdminNews />} />
          <Route path="/parking" element={<ParkingManager />} />
          <Route path="/lost-found" element={<LostFoundApprovals />} />
          {user.role === 'cafeteria_manager' && <Route path="/cafeteria" element={<CafeteriaManager />} />}
          <Route path="/shuttles" element={<ShuttleManager />} />
          <Route path="/events" element={<EventManager />} />
          <Route path="/study-rooms" element={<StudyRoomManager />} />
          <Route path="/feedback" element={<FeedbackManager />} />
          <Route path="/support" element={<SupportInbox />} />
          <Route path="*" element={<div className="card glass">Module Coming Soon</div>} />
        </Routes>
      </div>
    </div>
  );
}

function SidebarLink({ to, icon, label, active }) {
  return (
    <Link to={to} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem 1rem', borderRadius: '0.75rem', textDecoration: 'none', color: active ? 'white' : 'var(--muted)', background: active ? 'var(--card)' : 'transparent', fontWeight: active ? 700 : 500, transition: '0.2s' }}>
      {icon} {label}
    </Link>
  );
}
function UserRegistry() {
  const [users, setUsers] = useState([]);
  const [shops, setShops] = useState([]);
  const [shopsLoading, setShopsLoading] = useState(false);
  const [shopActionBusyId, setShopActionBusyId] = useState('');
  const [creating, setCreating] = useState(false);
  const [savingEdit, setSavingEdit] = useState(false);
  const [selectedRoleView, setSelectedRoleView] = useState('security');
  const [pendingDelete, setPendingDelete] = useState(null);
  const [createError, setCreateError] = useState('');
  const [createSuccess, setCreateSuccess] = useState('');
  const [generatedCredentials, setGeneratedCredentials] = useState(null);
  const [copiedCredentials, setCopiedCredentials] = useState(false);
  const [editingUserId, setEditingUserId] = useState('');
  const [editForm, setEditForm] = useState({ name: '', email: '', role: '' });
  const [form, setForm] = useState({
    name: '',
    email: '',
    role: '',
  });

  const adminUser = JSON.parse(localStorage.getItem('user') || '{}');
  const backendBaseUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5001';
  const adminPortalKey = import.meta.env.VITE_ADMIN_PORTAL_KEY || '';

  const fetchUsers = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'users'));
      const usersList = querySnapshot.docs.map((docItem) => ({ id: docItem.id, ...docItem.data() }));
      setUsers(usersList);
    } catch (error) {
      console.error('Error fetching users:', error);
    }
  };

  const fetchShops = async () => {
    setShopsLoading(true);
    try {
      const snapshot = await getDocs(collection(db, 'cafeteria_shops'));
      const list = snapshot.docs.map((docItem) => ({ id: docItem.id, ...docItem.data() }));
      setShops(list);
    } catch (error) {
      console.error('Error fetching shops:', error);
    } finally {
      setShopsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
    fetchShops();
  }, []);

  const upsertCafeteriaShopByEmail = async ({ shopName, shopEmail }) => {
    const normalizedEmail = String(shopEmail || '').trim().toLowerCase();
    const normalizedShopName = String(shopName || '').trim();
    if (!normalizedEmail || !normalizedShopName) return;

    const existingShop = await getDocs(
      query(collection(db, 'cafeteria_shops'), where('shopEmail', '==', normalizedEmail), limit(1))
    );

    const payload = {
      shopName: normalizedShopName,
      shopEmail: normalizedEmail,
      isActive: true,
      updatedAt: serverTimestamp(),
    };

    if (!existingShop.empty) {
      await updateDoc(doc(db, 'cafeteria_shops', existingShop.docs[0].id), payload);
      return;
    }

    await addDoc(collection(db, 'cafeteria_shops'), {
      ...payload,
      createdAt: serverTimestamp(),
    });
  };

  const removeShop = async (shop) => {
    const targetName = shop?.shopName || 'this shop';
    const confirmed = window.confirm(`Remove ${targetName} from shop database?`);
    if (!confirmed) return;

    setShopActionBusyId(shop.id);
    setCreateError('');
    setCreateSuccess('');
    try {
      await deleteDoc(doc(db, 'cafeteria_shops', shop.id));
      setCreateSuccess(`${targetName} removed from shop database.`);
      await fetchShops();
    } catch (error) {
      console.error('Error removing shop:', error);
      setCreateError('Failed to remove shop from database.');
    } finally {
      setShopActionBusyId('');
    }
  };

  const visibleUsers = users.filter((u) => (u.role || '').toLowerCase() !== 'admin');
  const securityUsers = visibleUsers.filter((u) => u.role === 'security');
  const cafeteriaUsers = visibleUsers.filter((u) => u.role === 'cafeteria_manager');
  const studentUsers = visibleUsers.filter((u) => u.role === 'student');

  const sections = {
    security: {
      title: 'Security Users',
      users: securityUsers,
      accent: '#38bdf8',
    },
    cafeteria_manager: {
      title: 'Cafeteria Manager Users',
      users: cafeteriaUsers,
      accent: '#f59e0b',
    },
    transport_manager: {
      title: 'Transport Manager Users',
      users: visibleUsers.filter((u) => u.role === 'transport_manager'),
      accent: '#0ea5e9',
    },
    student: {
      title: 'Student Users',
      users: studentUsers,
      accent: '#22c55e',
    },
  };

  const roleNameLabel = form.role === 'cafeteria_manager' ? 'CAFETERIA SHOP NAME' : 'SECURITY OFFICER NAME';
  const roleNamePlaceholder = form.role === 'cafeteria_manager' ? 'e.g. Campus Cafe Central' : 'e.g. Nimal Perera';
  const emailPlaceholder = form.role === 'cafeteria_manager' ? 'cafe.manager@unilink.com' : 'security.officer@unilink.com';
  const normalizeStaffRole = (rawRole) => {
    const normalized = String(rawRole || '')
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, '_');
    if (normalized === 'cafeteria' || normalized === 'cafe_manager') return 'cafeteria_manager';
    if ([
      'cafeteria_manager',
      'security',
      'transport_manager',
      'student'
    ].includes(normalized)) return normalized;
    return '';
  };

  const generatePassword = (rawName) => {
    const normalized = String(rawName || '').trim().toLowerCase().replace(/[^a-z0-9]/g, '');
    const base = normalized || 'staff';
    const digits = Math.floor(100 + Math.random() * 900);
    return `${base}${digits}`;
  };

  const getErrorText = (error, fallback) => {
    const responseMessage = error?.response?.data?.message;
    const directMessage = error?.message;
    if (typeof responseMessage === 'string' && responseMessage.trim()) return responseMessage;
    if (typeof directMessage === 'string' && directMessage.trim()) return directMessage;
    return fallback;
  };

  const createAuthUserViaFirebaseRest = async ({ email, password, displayName }) => {
    const firebaseApiKey = import.meta.env.VITE_FIREBASE_WEB_API_KEY || db?.app?.options?.apiKey;
    if (!firebaseApiKey) {
      throw new Error('Backend unreachable and Firebase API key is missing (set VITE_FIREBASE_WEB_API_KEY).');
    }

    const signUpResponse = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${firebaseApiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email,
          password,
          returnSecureToken: true,
        }),
      }
    );

    const signUpData = await signUpResponse.json();
    if (!signUpResponse.ok) {
      const firebaseError = signUpData?.error?.message || 'Unknown Firebase error';
      if (firebaseError === 'EMAIL_EXISTS') {
        return {
          existing: true,
          message: 'Firebase Auth user already exists for this email',
        };
      }
      throw new Error(`Firebase REST create failed: ${firebaseError}`);
    }

    const uid = signUpData?.localId || '';

    if (displayName && signUpData?.idToken) {
      await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:update?key=${firebaseApiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            idToken: signUpData.idToken,
            displayName,
            returnSecureToken: false,
          }),
        }
      );
    }

    return {
      existing: false,
      uid,
      message: 'Firebase Auth account created successfully (REST fallback).',
    };
  };

  const handleCreateStaff = async (e) => {
    e.preventDefault();
    setCreateError('');
    setCreateSuccess('');
    setGeneratedCredentials(null);
    setCopiedCredentials(false);
    setCreating(true);

    try {
      const selectedRole = normalizeStaffRole(form.role);

      if (!selectedRole) {
        setCreateError('Please select a role first.');
        return;
      }

      const email = form.email.trim().toLowerCase();
      const generatedPassword = generatePassword(form.name);
      const existing = await getDocs(
        query(collection(db, 'users'), where('email', '==', email), limit(1))
      );

      const replacedExistingProfile = !existing.empty;

      if (replacedExistingProfile) {
        await Promise.all(existing.docs.map((userDoc) => deleteDoc(doc(db, 'users', userDoc.id))));
      }

      let authCreateResponse;
      try {
        authCreateResponse = await axios.post(
          `${backendBaseUrl}/api/v1/admin/create-auth-user`,
          {
            email,
            password: generatedPassword,
            displayName: form.name.trim(),
          },
          {
            headers: adminPortalKey ? { 'x-admin-key': adminPortalKey } : {},
          }
        );
      } catch (authError) {
        const isNetworkError = !authError?.response;
        if (!isNetworkError) {
          const authErrorText = getErrorText(authError, 'Unable to create Firebase Auth account.');
          throw new Error(`Auth step failed: ${authErrorText}`);
        }

        try {
          const fallbackAuth = await createAuthUserViaFirebaseRest({
            email,
            password: generatedPassword,
            displayName: form.name.trim(),
          });
          authCreateResponse = { data: fallbackAuth };
        } catch (fallbackError) {
          const fallbackText = getErrorText(fallbackError, 'Unable to create Firebase Auth account.');
          throw new Error(`Auth step failed: ${fallbackText}`);
        }
      }

      const authMessage = authCreateResponse?.data?.existing
        ? 'Existing Firebase Auth account reused for this email.'
        : 'Firebase Auth account created successfully.';
      const profileMessage = replacedExistingProfile
        ? 'Previous registry record replaced.'
        : 'New registry record created.';

      try {
        const uid = authCreateResponse?.data?.uid || authCreateResponse?.data?.localId || authCreateResponse?.data?.user?.uid;
        
        const profileData = {
          name: form.name.trim(),
          email,
          role: selectedRole,
          approvedByAdmin: true,
          isActive: true,
          createdBy: adminUser.email || 'admin',
          createdAt: serverTimestamp(),
        };

        if (uid) {
          await setDoc(doc(db, 'users', uid), profileData);
        } else {
          // Fallback if UID is somehow missing from response
          await addDoc(collection(db, 'users'), profileData);
        }
      } catch (profileError) {
        const profileErrorText = getErrorText(profileError, 'Unable to save staff profile in Firestore.');
        throw new Error(`Profile step failed: ${profileErrorText}`);
      }

      if (selectedRole === 'cafeteria_manager') {
        try {
          await upsertCafeteriaShopByEmail({
            shopName: form.name.trim(),
            shopEmail: email,
          });
        } catch (shopSyncError) {
          const shopSyncErrorText = getErrorText(shopSyncError, 'Unable to sync cafeteria shop details.');
          throw new Error(`Shop sync failed: ${shopSyncErrorText}`);
        }
      }

      setGeneratedCredentials({
        name: form.name.trim(),
        email,
        role: selectedRole,
        password: generatedPassword,
      });

      let emailMessage = 'Credential email sent automatically.';
      let emailFailed = false;
      try {
        await axios.post(
          `${backendBaseUrl}/api/v1/admin/send-credentials`,
          {
            toEmail: email,
            staffName: form.name.trim(),
            role: selectedRole,
            password: generatedPassword,
          },
          {
            headers: adminPortalKey ? { 'x-admin-key': adminPortalKey } : {},
          }
        );
      } catch (mailError) {
        const backendMessage = mailError?.response?.data?.message;
        emailMessage = backendMessage || 'Auto email failed. Use Copy Credential Message or Send As Email Message.';
        emailFailed = true;
      }

      if (emailFailed) {
        setCreateError(`Staff member added. ${authMessage} ${profileMessage} ${emailMessage}`);
        setCreateSuccess('');
      } else {
        const createdRoleLabel = selectedRole === 'cafeteria_manager' ? 'Cafeteria Manager' : 'Security';
        setCreateSuccess(`${createdRoleLabel} account added successfully. ${authMessage} ${profileMessage} ${emailMessage}`);
      }
      setSelectedRoleView(selectedRole);
      setForm({ name: '', email: '', role: '' });
      await fetchUsers();
    } catch (error) {
      console.error('Error creating staff profile:', error);
      setCreateError(getErrorText(error, 'Failed to add staff member. Please try again.'));
    } finally {
      setCreating(false);
    }
  };

  const copyCredentialMessage = async () => {
    if (!generatedCredentials) return;

    const roleLabel = generatedCredentials.role === 'cafeteria_manager' ? 'Cafeteria Manager' : 'Security';
    const message = [
      `Hello ${generatedCredentials.name},`,
      '',
      'Your UniLink staff account is ready.',
      `Email: ${generatedCredentials.email}`,
      `Role: ${roleLabel}`,
      `Temporary Password: ${generatedCredentials.password}`,
      '',
      'Please login and change your password immediately.',
    ].join('\n');

    try {
      await navigator.clipboard.writeText(message);
      setCopiedCredentials(true);
      setTimeout(() => setCopiedCredentials(false), 1800);
    } catch (error) {
      console.error('Credential message copy failed:', error);
      setCreateError('Could not copy credential message. Please copy it manually.');
    }
  };

  const openCredentialEmailDraft = () => {
    if (!generatedCredentials) return;

    const roleLabel = generatedCredentials.role === 'cafeteria_manager' ? 'Cafeteria Manager' : 'Security';
    const message = [
      `Hello ${generatedCredentials.name},`,
      '',
      'Your UniLink staff account is ready.',
      `Email: ${generatedCredentials.email}`,
      `Role: ${roleLabel}`,
      `Temporary Password: ${generatedCredentials.password}`,
      '',
      'Please login and change your password immediately.',
    ].join('\n');

    try {
      const subject = encodeURIComponent('UniLink Staff Account Credentials');
      const body = encodeURIComponent(message);
      const targetEmail = encodeURIComponent(generatedCredentials.email);
      window.open(`mailto:${targetEmail}?subject=${subject}&body=${body}`, '_blank');
    } catch (error) {
      console.error('Credential email draft open failed:', error);
      setCreateError('Could not open email draft. Please copy and send manually.');
    }
  };

  const startEditUser = (user) => {
    setEditingUserId(user.id);
    setEditForm({
      name: user.name || '',
      email: user.email || '',
      role: user.role || 'security',
    });
  };

  const cancelEditUser = () => {
    setEditingUserId('');
    setEditForm({ name: '', email: '', role: '' });
  };

  const saveEditUser = async (userId) => {
    if (!editForm.name.trim() || !editForm.email.trim()) {
      setCreateError('Name and email are required for update.');
      return;
    }

    setSavingEdit(true);
    setCreateError('');
    setCreateSuccess('');

    try {
      const targetUser = users.find((item) => item.id === userId) || null;
      const payload = {
        name: editForm.name.trim(),
        email: editForm.email.trim().toLowerCase(),
        role: editForm.role,
        updatedAt: serverTimestamp(),
      };

      try {
        await updateDoc(doc(db, 'users', userId), payload);
      } catch (primaryError) {
        const fallback = await getDocs(
          query(collection(db, 'users'), where('email', '==', editForm.email.trim().toLowerCase()), limit(1))
        );

        if (fallback.empty) {
          throw primaryError;
        }

        await updateDoc(doc(db, 'users', fallback.docs[0].id), payload);
      }

      if (payload.role === 'cafeteria_manager') {
        await upsertCafeteriaShopByEmail({
          shopName: payload.name,
          shopEmail: payload.email,
        });
      } else if ((targetUser?.role || '').toLowerCase() === 'cafeteria_manager') {
        const relatedShops = await getDocs(
          query(collection(db, 'cafeteria_shops'), where('shopEmail', '==', payload.email), limit(5))
        );
        if (!relatedShops.empty) {
          await Promise.all(
            relatedShops.docs.map((shopDoc) => deleteDoc(doc(db, 'cafeteria_shops', shopDoc.id)))
          );
        }
      }

      setCreateSuccess('User updated successfully.');
      cancelEditUser();
      await fetchUsers();
      await fetchShops();
    } catch (error) {
      console.error('Error updating user:', error);
      setCreateError('Failed to update user.');
    } finally {
      setSavingEdit(false);
    }
  };

  const confirmDeleteUser = async (userId) => {
    setCreateError('');
    setCreateSuccess('');

    try {
      const userToDelete = users.find((u) => u.id === userId) || null;
      const deletePayload = userToDelete?.email
        ? { email: userToDelete.email.trim().toLowerCase() }
        : { uid: userId };

      let authDeleteWarning = '';

      try {
        await axios.post(
          `${backendBaseUrl}/api/v1/admin/delete-auth-user`,
          deletePayload,
          {
            headers: adminPortalKey ? { 'x-admin-key': adminPortalKey } : {},
          }
        );
      } catch (authDeleteError) {
        const statusCode = authDeleteError?.response?.status;
        if (statusCode !== 404) {
          const backendMessage = authDeleteError?.response?.data?.message;
          authDeleteWarning = backendMessage || 'Firebase Auth user could not be deleted.';
        }
      }

      try {
        await deleteDoc(doc(db, 'users', userId));
      } catch (primaryError) {
        const fallbackEmail = userToDelete?.email?.trim()?.toLowerCase();

        if (!fallbackEmail) {
          throw primaryError;
        }

        const fallback = await getDocs(
          query(collection(db, 'users'), where('email', '==', fallbackEmail), limit(1))
        );

        if (fallback.empty) {
          throw primaryError;
        }

        await deleteDoc(doc(db, 'users', fallback.docs[0].id));
      }

      if (editingUserId === userId) {
        cancelEditUser();
      }

      if (userToDelete?.email) {
        const matchingShops = await getDocs(
          query(
            collection(db, 'cafeteria_shops'),
            where('shopEmail', '==', userToDelete.email.trim().toLowerCase())
          )
        );
        if (!matchingShops.empty) {
          await Promise.all(
            matchingShops.docs.map((shopDoc) => deleteDoc(doc(db, 'cafeteria_shops', shopDoc.id)))
          );
        }
      }

      setPendingDelete(null);
      setCreateSuccess(authDeleteWarning ? `User deleted from registry. ${authDeleteWarning}` : 'User deleted successfully.');
      await fetchUsers();
      await fetchShops();
    } catch (error) {
      console.error('Error deleting user:', error);
      setCreateError('Failed to delete user.');
    }
  };

  const renderRoleSection = (title, roleUsers, accent) => (
    <div className="card glass" style={{ padding: '1rem 1.25rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.9rem' }}>
        <h4 style={{ margin: 0, color: accent, fontWeight: 900 }}>{title}</h4>
        <span style={{ color: 'var(--muted)', fontWeight: 700, fontSize: '0.85rem' }}>{roleUsers.length} users</span>
      </div>

      {roleUsers.length === 0 ? (
        <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No users in this role.</div>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ textAlign: 'left', borderBottom: '1px solid var(--border)' }}>
              <th style={{ padding: '0.75rem', color: 'var(--muted)', fontSize: '0.75rem', fontWeight: 800 }}>NAME</th>
              <th style={{ padding: '0.75rem', color: 'var(--muted)', fontSize: '0.75rem', fontWeight: 800 }}>EMAIL</th>
              <th style={{ padding: '0.75rem', color: 'var(--muted)', fontSize: '0.75rem', fontWeight: 800 }}>ROLE</th>
              <th style={{ padding: '0.75rem', color: 'var(--muted)', fontSize: '0.75rem', fontWeight: 800 }}>ACTIONS</th>
            </tr>
          </thead>
          <tbody>
            {roleUsers.map((u) => {
              const isEditing = editingUserId === u.id;
              return (
                <tr key={u.id} style={{ borderBottom: '1px solid var(--border)' }}>
                  <td style={{ padding: '0.75rem', fontWeight: 700 }}>
                    {isEditing ? (
                      <input
                        className="input-field"
                        style={{ paddingLeft: '0.75rem' }}
                        value={editForm.name}
                        onChange={(e) => setEditForm((prev) => ({ ...prev, name: e.target.value }))}
                      />
                    ) : (
                      u.name
                    )}
                  </td>
                  <td style={{ padding: '0.75rem', color: 'var(--muted)' }}>
                    {isEditing ? (
                      <input
                        className="input-field"
                        style={{ paddingLeft: '0.75rem' }}
                        value={editForm.email}
                        onChange={(e) => setEditForm((prev) => ({ ...prev, email: e.target.value }))}
                      />
                    ) : (
                      u.email
                    )}
                  </td>
                  <td style={{ padding: '0.75rem' }}>
                    {isEditing ? (
                      <select
                        value={editForm.role}
                        onChange={(e) => setEditForm((prev) => ({ ...prev, role: e.target.value }))}
                        style={{ width: '100%', boxSizing: 'border-box', padding: '0.75rem', borderRadius: '0.7rem', background: '#0f172a', border: '1px solid var(--border)', color: 'white', fontWeight: 700 }}
                      >
                        <option value="security">Security</option>
                        <option value="cafeteria_manager">Cafeteria Manager</option>
                        <option value="student">Student</option>
                      </select>
                    ) : (
                      <span style={{ padding: '0.2rem 0.6rem', borderRadius: '999px', fontSize: '0.72rem', fontWeight: 800, background: 'rgba(148,163,184,0.15)', color: '#cbd5e1' }}>
                        {(u.role || 'unknown').toUpperCase()}
                      </span>
                    )}
                  </td>
                  <td style={{ padding: '0.75rem' }}>
                    <div style={{ display: 'flex', gap: '0.45rem' }}>
                      {isEditing ? (
                        <>
                          <button
                            type="button"
                            onClick={() => saveEditUser(u.id)}
                            disabled={savingEdit}
                            style={{ padding: '0.45rem 0.7rem', borderRadius: '0.55rem', border: 'none', background: '#14b8a6', color: 'white', fontWeight: 800, cursor: 'pointer' }}
                          >
                            Save
                          </button>
                          <button
                            type="button"
                            onClick={cancelEditUser}
                            style={{ padding: '0.45rem 0.7rem', borderRadius: '0.55rem', border: '1px solid var(--border)', background: 'transparent', color: '#cbd5e1', fontWeight: 800, cursor: 'pointer' }}
                          >
                            Cancel
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            type="button"
                            onClick={() => startEditUser(u)}
                            style={{ padding: '0.45rem 0.7rem', borderRadius: '0.55rem', border: '1px solid rgba(56,189,248,0.35)', background: 'rgba(56,189,248,0.1)', color: '#38bdf8', fontWeight: 800, cursor: 'pointer' }}
                          >
                            Edit
                          </button>
                          <button
                            type="button"
                            onClick={() => setPendingDelete({ id: u.id, name: u.name || 'this user' })}
                            style={{ padding: '0.45rem 0.7rem', borderRadius: '0.55rem', border: '1px solid rgba(244,63,94,0.35)', background: 'rgba(244,63,94,0.1)', color: '#f43f5e', fontWeight: 800, cursor: 'pointer' }}
                          >
                            Delete
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );

  return (
    <div style={{ display: 'grid', gap: '1.25rem' }}>
      <div className="card glass" style={{ padding: '1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h3 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Plus size={20} /> Add Staff Account</h3>
          <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#14b8a6', background: 'rgba(20,184,166,0.12)', border: '1px solid rgba(20,184,166,0.3)', borderRadius: '999px', padding: '0.3rem 0.65rem' }}>
            ADMIN CONTROLLED
          </span>
        </div>
        <p style={{ marginTop: 0, marginBottom: '1rem', color: 'var(--muted)', fontSize: '0.9rem' }}>
          Register only Security or Cafeteria Manager accounts. Newly added profiles are admin-approved.
        </p>

        <form onSubmit={handleCreateStaff} style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', columnGap: '1.4rem', rowGap: '0.9rem', alignItems: 'end', marginBottom: '0.5rem' }}>
          <div style={{ minWidth: 0 }}>
            <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>ROLE</label>
            <select
              value={form.role}
              onChange={(e) => setForm((prev) => ({ ...prev, role: e.target.value }))}
              style={{ width: '100%', boxSizing: 'border-box', padding: '1rem', borderRadius: '0.9rem', background: '#0f172a', border: '1px solid var(--border)', color: 'white', fontWeight: 700 }}
              required
            >
              <option value="">Select role</option>
              <option value="security">Security</option>
              <option value="cafeteria_manager">Cafeteria Manager</option>
              <option value="transport_manager">Transport Manager</option>
              <option value="student">Student</option>
            </select>
          </div>

          <div style={{ minWidth: 0 }}>
            <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>{roleNameLabel}</label>
            <input
              className="input-field"
              style={{ paddingLeft: '1rem', minWidth: 0 }}
              value={form.name}
              onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
              placeholder={form.role ? roleNamePlaceholder : 'Select role first'}
              required
              disabled={!form.role}
            />
          </div>

          <div style={{ minWidth: 0 }}>
            <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>EMAIL</label>
            <input
              type="email"
              className="input-field"
              style={{ paddingLeft: '1rem', minWidth: 0 }}
              value={form.email}
              onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))}
              placeholder={form.role ? emailPlaceholder : 'Select role first'}
              required
              disabled={!form.role}
            />
          </div>

          <button className="btn-primary" type="submit" disabled={creating} style={{ height: '52px', minWidth: '180px', background: '#8b5cf6', color: '#ffffff', width: '220px', gridColumn: '1 / -1', justifySelf: 'end', marginTop: '0.15rem' }}>
            {creating ? 'Adding...' : 'Add Staff'}
          </button>
        </form>

        {createError && <p style={{ color: '#f43f5e', marginBottom: 0, fontWeight: 700 }}>{createError}</p>}
        {createSuccess && <p style={{ color: '#14b8a6', marginBottom: 0, fontWeight: 700 }}>{createSuccess}</p>}
        <div style={{ marginTop: '0.9rem', border: '1px solid rgba(56,189,248,0.3)', background: 'rgba(56,189,248,0.08)', borderRadius: '0.9rem', padding: '0.9rem 1rem' }}>
          <div style={{ fontSize: '0.75rem', letterSpacing: '0.06em', color: '#7dd3fc', fontWeight: 800, marginBottom: '0.3rem' }}>
            CREDENTIALS DELIVERY
          </div>
          <div style={{ fontSize: '0.82rem', color: '#cbd5e1', lineHeight: 1.5 }}>
            System creates the Firebase Auth account with a generated password. Copy and send that credential message to the staff member.
          </div>
        </div>

        {generatedCredentials && (
          <div style={{ marginTop: '0.9rem', border: '1px solid rgba(20,184,166,0.35)', background: 'rgba(20,184,166,0.12)', borderRadius: '0.9rem', padding: '0.9rem 1rem' }}>
            <div style={{ fontSize: '0.75rem', letterSpacing: '0.06em', color: '#5eead4', fontWeight: 800, marginBottom: '0.5rem' }}>
              GENERATED CREDENTIALS
            </div>
            <div style={{ fontSize: '0.85rem', color: '#e2e8f0', lineHeight: 1.6 }}>
              <div>Email: <strong>{generatedCredentials.email}</strong></div>
              <div>Password: <strong>{generatedCredentials.password}</strong></div>
            </div>
            <button
              type="button"
              onClick={copyCredentialMessage}
              style={{ marginTop: '0.7rem', padding: '0.45rem 0.75rem', borderRadius: '0.6rem', border: '1px solid rgba(94,234,212,0.4)', background: 'rgba(94,234,212,0.12)', color: '#5eead4', fontWeight: 800, cursor: 'pointer' }}
            >
              {copiedCredentials ? 'Copied' : 'Copy Credential Message'}
            </button>
            <button
              type="button"
              onClick={openCredentialEmailDraft}
              style={{ marginTop: '0.7rem', marginLeft: '0.55rem', padding: '0.45rem 0.75rem', borderRadius: '0.6rem', border: '1px solid rgba(56,189,248,0.4)', background: 'rgba(56,189,248,0.12)', color: '#38bdf8', fontWeight: 800, cursor: 'pointer' }}
            >
              Send As Email Message
            </button>
          </div>
        )}
      </div>

      <div className="card glass" style={{ padding: '1rem 1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.9rem', gap: '0.7rem', flexWrap: 'wrap' }}>
          <h4 style={{ margin: 0, color: '#f59e0b', fontWeight: 900 }}>Cafeteria Shops Database</h4>
          <span style={{ color: 'var(--muted)', fontWeight: 700, fontSize: '0.82rem' }}>
            {shopsLoading ? 'Loading...' : `${shops.length} shops`}
          </span>
        </div>

        {shops.length === 0 ? (
          <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No cafeteria shops saved yet.</div>
        ) : (
          <div style={{ display: 'grid', gap: '0.7rem' }}>
            {shops.map((shop) => (
              <div key={shop.id} style={{ border: '1px solid var(--border)', borderRadius: '0.8rem', padding: '0.75rem 0.85rem', background: 'rgba(255,255,255,0.02)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '0.8rem', flexWrap: 'wrap' }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontWeight: 800 }}>{shop.shopName || 'Unnamed shop'}</div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--muted)', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {shop.shopEmail || 'No email'}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => removeShop(shop)}
                  disabled={shopActionBusyId === shop.id}
                  style={{ padding: '0.42rem 0.7rem', borderRadius: '0.55rem', border: '1px solid rgba(244,63,94,0.35)', background: 'rgba(244,63,94,0.1)', color: '#f43f5e', fontWeight: 800, cursor: shopActionBusyId === shop.id ? 'not-allowed' : 'pointer' }}
                >
                  {shopActionBusyId === shop.id ? 'Removing...' : 'Remove Shop'}
                </button>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="card glass" style={{ padding: '1rem 1.25rem' }}>
        <div style={{ display: 'flex', gap: '0.6rem', flexWrap: 'wrap' }}>
          <button
            type="button"
            onClick={() => setSelectedRoleView('security')}
            style={{
              padding: '0.5rem 0.8rem',
              borderRadius: '999px',
              border: `1px solid ${selectedRoleView === 'security' ? '#38bdf8' : 'var(--border)'}`,
              background: selectedRoleView === 'security' ? 'rgba(56,189,248,0.16)' : 'rgba(255,255,255,0.03)',
              color: selectedRoleView === 'security' ? '#38bdf8' : '#cbd5e1',
              fontWeight: 800,
              cursor: 'pointer'
            }}
          >
            Security ({securityUsers.length})
          </button>
          <button
            type="button"
            onClick={() => setSelectedRoleView('cafeteria_manager')}
            style={{
              padding: '0.5rem 0.8rem',
              borderRadius: '999px',
              border: `1px solid ${selectedRoleView === 'cafeteria_manager' ? '#f59e0b' : 'var(--border)'}`,
              background: selectedRoleView === 'cafeteria_manager' ? 'rgba(245,158,11,0.16)' : 'rgba(255,255,255,0.03)',
              color: selectedRoleView === 'cafeteria_manager' ? '#f59e0b' : '#cbd5e1',
              fontWeight: 800,
              cursor: 'pointer'
            }}
          >
            Cafeteria ({cafeteriaUsers.length})
          </button>
          <button
            type="button"
            onClick={() => setSelectedRoleView('transport_manager')}
            style={{
              padding: '0.5rem 0.8rem',
              borderRadius: '999px',
              border: `1px solid ${selectedRoleView === 'transport_manager' ? '#0ea5e9' : 'var(--border)'}`,
              background: selectedRoleView === 'transport_manager' ? 'rgba(14,165,233,0.16)' : 'rgba(255,255,255,0.03)',
              color: selectedRoleView === 'transport_manager' ? '#0ea5e9' : '#cbd5e1',
              fontWeight: 800,
              cursor: 'pointer'
            }}
          >
            Transport Manager ({sections.transport_manager.users.length})
          </button>
          <button
            type="button"
            onClick={() => setSelectedRoleView('student')}
            style={{
              padding: '0.5rem 0.8rem',
              borderRadius: '999px',
              border: `1px solid ${selectedRoleView === 'student' ? '#22c55e' : 'var(--border)'}`,
              background: selectedRoleView === 'student' ? 'rgba(34,197,94,0.16)' : 'rgba(255,255,255,0.03)',
              color: selectedRoleView === 'student' ? '#22c55e' : '#cbd5e1',
              fontWeight: 800,
              cursor: 'pointer'
            }}
          >
            Students ({studentUsers.length})
          </button>
        </div>
      </div>

      {renderRoleSection(
        sections[selectedRoleView].title,
        sections[selectedRoleView].users,
        sections[selectedRoleView].accent
      )}

      {pendingDelete && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(2, 6, 23, 0.72)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999 }}>
          <div className="glass" style={{ width: '100%', maxWidth: '420px', borderRadius: '1rem', border: '1px solid var(--border)', padding: '1.2rem' }}>
            <h4 style={{ marginTop: 0, marginBottom: '0.6rem' }}>Delete User</h4>
            <p style={{ marginTop: 0, color: 'var(--muted)' }}>
              Are you sure you want to delete <strong>{pendingDelete.name}</strong>?
            </p>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.6rem' }}>
              <button
                type="button"
                onClick={() => setPendingDelete(null)}
                style={{ padding: '0.5rem 0.8rem', borderRadius: '0.6rem', border: '1px solid var(--border)', background: 'transparent', color: '#cbd5e1', fontWeight: 700, cursor: 'pointer' }}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => confirmDeleteUser(pendingDelete.id)}
                style={{ padding: '0.5rem 0.8rem', borderRadius: '0.6rem', border: '1px solid rgba(244,63,94,0.35)', background: '#f43f5e', color: 'white', fontWeight: 800, cursor: 'pointer' }}
              >
                OK
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}


function Overview({ user }) {
  const navigate = useNavigate();
  useEffect(() => {
    if (user.role === 'transport_manager') {
      navigate('/dashboard/shuttles', { replace: true });
    }
  }, [user.role, navigate]);

  if (user.role === 'admin') {
    return <AdminOverview />;
  }

  if (user.role === 'security') {
    return <SecurityOverview />;
  }

  if (user.role === 'cafeteria_manager') {
    return <CafeteriaOverview user={user} />;
  }

  // Hide Overview content for transport_manager and others
  return null;
}

function CafeteriaOverview({ user }) {
  const [menuItems, setMenuItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [ordersLoading, setOrdersLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [actionBusyId, setActionBusyId] = useState('');
  const [editingItemId, setEditingItemId] = useState('');
  const [formError, setFormError] = useState('');
  const [formSuccess, setFormSuccess] = useState('');
  const [orderStats, setOrderStats] = useState({
    todayOrders: 0,
    pendingOrPreparing: 0,
    completedToday: 0,
    todayRevenue: 0,
  });
  const [recentOrders, setRecentOrders] = useState([]);
  const [form, setForm] = useState({
    name: '',
    description: '',
    price: '',
    currency: 'LKR',
    imageUrl: '',
    quantity: '',
    preparationMinutes: '15',
    category: 'Main',
    status: 'Available',
  });

  const formatPrice = (value, currencyCode = 'LKR') => {
    const amount = Number(value || 0);
    const normalizedAmount = Number.isFinite(amount) ? amount : 0;
    try {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currencyCode || 'LKR',
      }).format(normalizedAmount);
    } catch (_) {
      return `Rs. ${normalizedAmount.toFixed(2)}`;
    }
  };

  const toDateSafe = (rawValue) => {
    if (!rawValue) return null;
    if (rawValue?.toDate) return rawValue.toDate();
    if (rawValue?.seconds) return new Date(rawValue.seconds * 1000);
    const parsed = new Date(rawValue);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  };

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, 'cafeteria_menu'),
      (snapshot) => {
        const items = snapshot.docs
          .map((docItem) => ({ id: docItem.id, ...docItem.data() }))
          .sort((a, b) => {
            const left = b?.createdAt?.toMillis?.() || 0;
            const right = a?.createdAt?.toMillis?.() || 0;
            return left - right;
          });
        setMenuItems(items);
        setLoading(false);
      },
      (error) => {
        console.error('Error loading cafeteria menu:', error);
        setLoading(false);
      }
    );

    return () => unsub();
  }, []);

  useEffect(() => {
    const ordersQuery = query(collection(db, 'orders'), orderBy('createdAt', 'desc'));
    const unsubOrders = onSnapshot(
      ordersQuery,
      (snapshot) => {
        const allOrders = snapshot.docs.map((docItem) => ({ id: docItem.id, ...docItem.data() }));
        const now = new Date();
        const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        const todayOrders = allOrders.filter((order) => {
          const orderDate = toDateSafe(order.createdAt);
          return orderDate && orderDate >= startOfToday;
        });

        const pendingOrPreparing = todayOrders.filter((order) => {
          const normalized = String(order.status || '').toLowerCase();
          return normalized === 'pending' || normalized === 'preparing' || normalized === 'ready';
        }).length;

        const completedToday = todayOrders.filter((order) => String(order.status || '').toLowerCase() === 'completed').length;
        const todayRevenue = todayOrders.reduce((sum, order) => sum + Number(order.totalAmount || 0), 0);

        setOrderStats({
          todayOrders: todayOrders.length,
          pendingOrPreparing,
          completedToday,
          todayRevenue,
        });
        setRecentOrders(allOrders.slice(0, 6));
        setOrdersLoading(false);
      },
      (error) => {
        console.error('Error loading cafeteria order overview:', error);
        setOrdersLoading(false);
      }
    );

    return () => unsubOrders();
  }, []);

  const resetForm = () => {
    setForm({
      name: '',
      description: '',
      price: '',
      currency: 'LKR',
      imageUrl: '',
      quantity: '',
      preparationMinutes: '15',
      category: 'Main',
      status: 'Available',
    });
    setEditingItemId('');
  };

  const handleSubmitMenu = async (event) => {
    event.preventDefault();
    setFormError('');
    setFormSuccess('');

    const normalizedName = String(form.name || '').trim();
    const normalizedDescription = String(form.description || '').trim();
    const parsedPrice = Number.parseFloat(String(form.price || '').trim());
    const normalizedImageUrl = String(form.imageUrl || '').trim();
    const parsedQuantity = Number.parseInt(String(form.quantity || '').trim(), 10);
    const parsedPreparationMinutes = Number.parseInt(String(form.preparationMinutes || '').trim(), 10);

    if (!normalizedName) {
      setFormError('Food name is required.');
      return;
    }

    if (!Number.isFinite(parsedPrice) || parsedPrice <= 0) {
      setFormError('Enter a valid food price greater than 0.');
      return;
    }

    if (!Number.isInteger(parsedQuantity) || parsedQuantity < 0) {
      setFormError('Enter a valid quantity (0 or more).');
      return;
    }

    if (!Number.isInteger(parsedPreparationMinutes) || parsedPreparationMinutes <= 0) {
      setFormError('Preparation time must be a positive number of minutes.');
      return;
    }

    const normalizedStatus = parsedQuantity === 0
      ? 'Unavailable'
      : form.status === 'Unavailable'
        ? 'Unavailable'
        : 'Available';

    const payload = {
      name: normalizedName,
      description: normalizedDescription,
      price: Number(parsedPrice.toFixed(2)),
      currency: String(form.currency || 'LKR').trim().toUpperCase() || 'LKR',
      image: normalizedImageUrl,
      imageUrl: normalizedImageUrl,
      quantity: parsedQuantity,
      preparationMinutes: parsedPreparationMinutes,
      category: String(form.category || 'Main').trim() || 'Main',
      status: normalizedStatus,
      updatedAt: serverTimestamp(),
      updatedBy: user?.email || 'cafeteria_manager',
    };

    setSaving(true);
    try {
      if (editingItemId) {
        await updateDoc(doc(db, 'cafeteria_menu', editingItemId), payload);
        setFormSuccess('Food item updated successfully.');
      } else {
        await addDoc(collection(db, 'cafeteria_menu'), {
          ...payload,
          createdAt: serverTimestamp(),
          createdBy: user?.email || 'cafeteria_manager',
        });
        setFormSuccess('Food item added to menu.');
      }
      resetForm();
    } catch (error) {
      console.error('Error saving menu item:', error);
      setFormError('Failed to save menu item. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const handleEditItem = (item) => {
    setEditingItemId(item.id);
    setFormError('');
    setFormSuccess('');
    setForm({
      name: item.name || '',
      description: item.description || '',
      price: String(item.price ?? ''),
      currency: String(item.currency || 'LKR'),
      imageUrl: String(item.image || item.imageUrl || ''),
      quantity: String(item.quantity ?? 0),
      preparationMinutes: String(item.preparationMinutes ?? 15),
      category: item.category || 'Main',
      status: item.status === 'Unavailable' ? 'Unavailable' : 'Available',
    });
  };

  const handleDeleteItem = async (item) => {
    const confirmed = window.confirm(`Delete ${item.name || 'this food item'} from menu?`);
    if (!confirmed) return;

    setActionBusyId(item.id);
    setFormError('');
    setFormSuccess('');
    try {
      await deleteDoc(doc(db, 'cafeteria_menu', item.id));
      if (editingItemId === item.id) {
        resetForm();
      }
      setFormSuccess('Food item removed from menu.');
    } catch (error) {
      console.error('Error deleting menu item:', error);
      setFormError('Failed to delete menu item.');
    } finally {
      setActionBusyId('');
    }
  };

  const toggleAvailability = async (item) => {
    const nextStatus = item.status === 'Available' ? 'Unavailable' : 'Available';

    if (nextStatus === 'Available' && Number(item.quantity || 0) <= 0) {
      setFormError('Cannot enable an item with quantity 0. Update quantity first.');
      setFormSuccess('');
      return;
    }

    setActionBusyId(item.id);
    setFormError('');
    setFormSuccess('');
    try {
      await updateDoc(doc(db, 'cafeteria_menu', item.id), {
        status: nextStatus,
        updatedAt: serverTimestamp(),
        updatedBy: user?.email || 'cafeteria_manager',
      });
      setFormSuccess(`Item marked as ${nextStatus}.`);
    } catch (error) {
      console.error('Error updating availability:', error);
      setFormError('Failed to update availability.');
    } finally {
      setActionBusyId('');
    }
  };

  const availableCount = menuItems.filter((item) => item.status !== 'Unavailable').length;
  const totalStock = menuItems.reduce((sum, item) => sum + Number(item.quantity || 0), 0);
  const averagePrice =
    menuItems.length > 0
      ? menuItems.reduce((sum, item) => sum + Number(item.price || 0), 0) / menuItems.length
      : 0;

  return (
    <div style={{ display: 'grid', gap: '1.5rem' }}>
      <div className="glass" style={{ borderRadius: '1.2rem', padding: '1.4rem', border: '1px solid var(--border)' }}>
        <p style={{ margin: 0, color: 'var(--muted)', fontWeight: 800, fontSize: '0.78rem', letterSpacing: '0.08em' }}>CAFETERIA OVERVIEW</p>
        <h3 style={{ margin: '0.5rem 0 0', fontSize: '1.5rem', fontWeight: 900 }}>Food Ops + Order Intelligence</h3>
        <p style={{ margin: '0.6rem 0 0', color: 'var(--muted)' }}>
          International-standard catalog fields, live order overview, and inventory-safe menu controls.
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))', gap: '1rem' }}>
        <MetricCard icon={<Utensils size={18} />} label="Total Foods" value={menuItems.length} tone="#f59e0b" />
        <MetricCard icon={<CheckCircle2 size={18} />} label="Available Items" value={availableCount} tone="#22c55e" />
        <MetricCard icon={<BarChart3 size={18} />} label="Average Price" value={formatPrice(averagePrice)} tone="#38bdf8" />
        <MetricCard icon={<Activity size={18} />} label="Total Stock" value={totalStock} tone="#a78bfa" />
      </div>

      <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
        <h4 style={{ margin: '0 0 1rem', fontWeight: 900 }}>Order Overview (Live)</h4>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(170px, 1fr))', gap: '0.8rem' }}>
          <div style={{ border: '1px solid var(--border)', borderRadius: '0.75rem', padding: '0.75rem', background: 'rgba(255,255,255,0.02)' }}>
            <div style={{ color: 'var(--muted)', fontSize: '0.78rem', fontWeight: 700 }}>TODAY ORDERS</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 900 }}>{orderStats.todayOrders}</div>
          </div>
          <div style={{ border: '1px solid var(--border)', borderRadius: '0.75rem', padding: '0.75rem', background: 'rgba(255,255,255,0.02)' }}>
            <div style={{ color: 'var(--muted)', fontSize: '0.78rem', fontWeight: 700 }}>PENDING / PREPARING</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 900, color: '#fbbf24' }}>{orderStats.pendingOrPreparing}</div>
          </div>
          <div style={{ border: '1px solid var(--border)', borderRadius: '0.75rem', padding: '0.75rem', background: 'rgba(255,255,255,0.02)' }}>
            <div style={{ color: 'var(--muted)', fontSize: '0.78rem', fontWeight: 700 }}>COMPLETED TODAY</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 900, color: '#22c55e' }}>{orderStats.completedToday}</div>
          </div>
          <div style={{ border: '1px solid var(--border)', borderRadius: '0.75rem', padding: '0.75rem', background: 'rgba(255,255,255,0.02)' }}>
            <div style={{ color: 'var(--muted)', fontSize: '0.78rem', fontWeight: 700 }}>TODAY REVENUE</div>
            <div style={{ fontSize: '1.35rem', fontWeight: 900, color: '#38bdf8' }}>{formatPrice(orderStats.todayRevenue, 'LKR')}</div>
          </div>
        </div>

        <div style={{ marginTop: '1rem', display: 'grid', gap: '0.6rem' }}>
          <div style={{ color: 'var(--muted)', fontSize: '0.78rem', fontWeight: 800, letterSpacing: '0.04em' }}>RECENT ORDERS</div>
          {ordersLoading ? (
            <div style={{ color: 'var(--muted)' }}>Loading recent orders...</div>
          ) : recentOrders.length === 0 ? (
            <div style={{ color: 'var(--muted)' }}>No orders yet.</div>
          ) : (
            recentOrders.map((order) => {
              const orderDate = toDateSafe(order.createdAt);
              const orderTimeLabel = orderDate
                ? orderDate.toLocaleString('en-GB', {
                    hour: '2-digit',
                    minute: '2-digit',
                    day: '2-digit',
                    month: 'short',
                  })
                : 'Time N/A';

              return (
                <div key={order.id} style={{ border: '1px solid var(--border)', borderRadius: '0.7rem', padding: '0.65rem 0.75rem', background: 'rgba(255,255,255,0.02)', display: 'grid', gridTemplateColumns: '1fr auto auto', gap: '0.7rem', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: 800 }}>#{order.orderNumber || order.id}</div>
                    <div style={{ color: 'var(--muted)', fontSize: '0.78rem' }}>{order.type || 'Order'} · {Array.isArray(order.items) ? order.items.length : 0} items · {orderTimeLabel}</div>
                  </div>
                  <div style={{ fontWeight: 800, color: '#fbbf24' }}>{formatPrice(order.totalAmount || 0, order.currency || 'LKR')}</div>
                  <span style={{ padding: '0.25rem 0.55rem', borderRadius: '999px', fontSize: '0.72rem', fontWeight: 800, background: String(order.status || '').toLowerCase() === 'completed' ? 'rgba(34,197,94,0.14)' : 'rgba(245,158,11,0.14)', color: String(order.status || '').toLowerCase() === 'completed' ? '#22c55e' : '#fbbf24' }}>
                    {String(order.status || 'unknown').toUpperCase()}
                  </span>
                </div>
              );
            })
          )}
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr', gap: '1rem' }}>
        <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
          <h4 style={{ margin: '0 0 1rem', fontWeight: 900 }}>{editingItemId ? 'Edit Food Item' : 'Add Food Item'}</h4>

          <form onSubmit={handleSubmitMenu} style={{ display: 'grid', gap: '0.8rem' }}>
            <div>
              <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>FOOD NAME</label>
              <input
                className="input-field"
                value={form.name}
                onChange={(event) => setForm({ ...form, name: event.target.value })}
                placeholder="e.g. Chicken Fried Rice"
                required
              />
            </div>

            <div>
              <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>DESCRIPTION (OPTIONAL)</label>
              <input
                className="input-field"
                value={form.description}
                onChange={(event) => setForm({ ...form, description: event.target.value })}
                placeholder="e.g. Basmati rice with grilled chicken"
              />
            </div>

            <div>
              <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>PRICE (LKR)</label>
              <input
                className="input-field"
                value={form.price}
                onChange={(event) => setForm({ ...form, price: event.target.value })}
                placeholder="e.g. 650"
                inputMode="decimal"
                required
              />
            </div>

            <div>
              <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>IMAGE URL (OPTIONAL)</label>
              <input
                className="input-field"
                value={form.imageUrl}
                onChange={(event) => setForm({ ...form, imageUrl: event.target.value })}
                placeholder="https://..."
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.8rem' }}>
              <div>
                <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>CATEGORY</label>
                <input
                  className="input-field"
                  value={form.category}
                  onChange={(event) => setForm({ ...form, category: event.target.value })}
                  placeholder="Main / Drinks / Snacks"
                />
              </div>
              <div>
                <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>CURRENCY</label>
                <select
                  className="input-field"
                  value={form.currency}
                  onChange={(event) => setForm({ ...form, currency: event.target.value })}
                >
                  <option value="LKR">LKR</option>
                  <option value="USD">USD</option>
                  <option value="EUR">EUR</option>
                </select>
              </div>
              <div>
                <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>QUANTITY</label>
                <input
                  className="input-field"
                  value={form.quantity}
                  onChange={(event) => setForm({ ...form, quantity: event.target.value })}
                  placeholder="e.g. 25"
                  inputMode="numeric"
                  required
                />
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.8rem' }}>
              <div>
                <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>PREP TIME (MIN)</label>
                <input
                  className="input-field"
                  value={form.preparationMinutes}
                  onChange={(event) => setForm({ ...form, preparationMinutes: event.target.value })}
                  placeholder="e.g. 15"
                  inputMode="numeric"
                  required
                />
              </div>
              <div>
                <label style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>STATUS</label>
                <select
                  className="input-field"
                  value={form.status}
                  onChange={(event) => setForm({ ...form, status: event.target.value })}
                >
                  <option value="Available">Available</option>
                  <option value="Unavailable">Unavailable</option>
                </select>
              </div>
            </div>

            {formError && <div style={{ color: '#f43f5e', fontWeight: 700, fontSize: '0.84rem' }}>{formError}</div>}
            {formSuccess && <div style={{ color: '#22c55e', fontWeight: 700, fontSize: '0.84rem' }}>{formSuccess}</div>}

            <div style={{ display: 'flex', gap: '0.7rem', flexWrap: 'wrap' }}>
              <button className="btn-primary" type="submit" disabled={saving}>
                {saving ? 'Saving...' : editingItemId ? 'Update Item' : 'Add Food'}
              </button>
              {editingItemId && (
                <button
                  type="button"
                  onClick={resetForm}
                  style={{ padding: '0.65rem 0.95rem', borderRadius: '0.7rem', border: '1px solid var(--border)', background: 'transparent', color: '#cbd5e1', fontWeight: 700, cursor: 'pointer' }}
                >
                  Cancel Edit
                </button>
              )}
            </div>
          </form>
        </div>

        <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
          <h4 style={{ margin: '0 0 1rem', fontWeight: 900 }}>Current Menu Items</h4>

          {loading ? (
            <div style={{ color: 'var(--muted)' }}>Loading menu items...</div>
          ) : menuItems.length === 0 ? (
            <div style={{ color: 'var(--muted)' }}>No food items yet. Add your first item from the left panel.</div>
          ) : (
            <div style={{ display: 'grid', gap: '0.75rem', maxHeight: '430px', overflowY: 'auto', paddingRight: '0.2rem' }}>
              {menuItems.map((item) => {
                const isBusy = actionBusyId === item.id;
                const available = item.status !== 'Unavailable';
                const itemQuantity = Number(item.quantity || 0);

                return (
                  <div key={item.id} style={{ border: '1px solid var(--border)', borderRadius: '0.8rem', padding: '0.8rem', background: 'rgba(255,255,255,0.02)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.7rem', alignItems: 'flex-start' }}>
                      <div style={{ display: 'flex', gap: '0.65rem', minWidth: 0 }}>
                        <div style={{ width: '44px', height: '44px', borderRadius: '0.65rem', background: 'rgba(255,255,255,0.06)', border: '1px solid var(--border)', overflow: 'hidden', flexShrink: 0 }}>
                          {item.image || item.imageUrl ? (
                            <img
                              src={item.image || item.imageUrl}
                              alt={item.name || 'Food item'}
                              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                            />
                          ) : (
                            <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#94a3b8', fontSize: '0.7rem', fontWeight: 800 }}>IMG</div>
                          )}
                        </div>
                        <div style={{ minWidth: 0 }}>
                          <div style={{ fontWeight: 800 }}>{item.name || 'Unnamed food'}</div>
                          <div style={{ fontSize: '0.8rem', color: 'var(--muted)' }}>
                            {item.category || 'Uncategorized'} · Qty {itemQuantity} · {item.preparationMinutes || 15} min
                          </div>
                          {item.description && (
                            <div style={{ fontSize: '0.75rem', color: '#94a3b8', marginTop: '0.2rem' }}>{item.description}</div>
                          )}
                        </div>
                      </div>
                      <span style={{ fontWeight: 900, color: '#fbbf24' }}>{formatPrice(item.price, item.currency || 'LKR')}</span>
                    </div>

                    <div style={{ marginTop: '0.65rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap' }}>
                      <span style={{ padding: '0.22rem 0.55rem', borderRadius: '999px', fontSize: '0.72rem', fontWeight: 800, background: available ? 'rgba(34,197,94,0.16)' : 'rgba(244,63,94,0.14)', color: available ? '#22c55e' : '#f43f5e' }}>
                        {available ? 'AVAILABLE' : 'UNAVAILABLE'}
                      </span>
                      <div style={{ display: 'flex', gap: '0.45rem' }}>
                        <button
                          type="button"
                          onClick={() => handleEditItem(item)}
                          disabled={isBusy}
                          style={{ padding: '0.35rem 0.62rem', borderRadius: '0.55rem', border: '1px solid #38bdf844', background: '#38bdf822', color: '#7dd3fc', fontSize: '0.76rem', fontWeight: 800, cursor: isBusy ? 'not-allowed' : 'pointer' }}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          onClick={() => toggleAvailability(item)}
                          disabled={isBusy}
                          style={{ padding: '0.35rem 0.62rem', borderRadius: '0.55rem', border: '1px solid #f59e0b44', background: '#f59e0b1f', color: '#fbbf24', fontSize: '0.76rem', fontWeight: 800, cursor: isBusy ? 'not-allowed' : 'pointer' }}
                        >
                          {isBusy ? '...' : available ? 'Disable' : 'Enable'}
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDeleteItem(item)}
                          disabled={isBusy}
                          style={{ padding: '0.35rem 0.62rem', borderRadius: '0.55rem', border: '1px solid #f43f5e44', background: '#f43f5e1f', color: '#f87171', fontSize: '0.76rem', fontWeight: 800, cursor: isBusy ? 'not-allowed' : 'pointer' }}
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function SecurityOverview() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    pending: 0,
    booked: 0,
    expiringSoon: 0,
    overdue: 0,
    openZones: 0,
  });
  const [recentPending, setRecentPending] = useState([]);

  const getRemainingLabel = (booking) => {
    const expiresAtMs = booking?.expiresAt?.seconds
      ? booking.expiresAt.seconds * 1000
      : null;
    if (!expiresAtMs) return 'No expiry set';

    const remainingMs = expiresAtMs - Date.now();
    if (remainingMs <= 0) return 'Expired';

    const minutes = Math.ceil(remainingMs / 60000);
    return `Expires in ${minutes} min`;
  };

  const loadSecurityOverview = async () => {
    setLoading(true);
    try {
      const [bookingsSnap, parkingSnap] = await Promise.all([
        getDocs(collection(db, 'parking_bookings')),
        getDocs(collection(db, 'parking')),
      ]);

      const bookings = bookingsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
      const pendingBookings = bookings.filter((item) => (item.status || '').toLowerCase() === 'pending');
      const bookedBookings = bookings.filter((item) => (item.status || '').toLowerCase() === 'booked');
      const nowMs = Date.now();

      const expiringSoon = pendingBookings.filter((item) => {
        const expiresAtMs = item?.expiresAt?.seconds ? item.expiresAt.seconds * 1000 : null;
        if (!expiresAtMs) return false;
        const remaining = expiresAtMs - nowMs;
        return remaining > 0 && remaining <= 5 * 60 * 1000;
      }).length;

      const overdue = pendingBookings.filter((item) => {
        const expiresAtMs = item?.expiresAt?.seconds ? item.expiresAt.seconds * 1000 : null;
        return expiresAtMs !== null && expiresAtMs <= nowMs;
      }).length;

      const zones = parkingSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
      const openZones = zones.filter((item) => Number(item.availableSlots || 0) > 0).length;

      const sortedPending = [...pendingBookings]
        .sort((a, b) => {
          const aMs = a?.expiresAt?.seconds ? a.expiresAt.seconds * 1000 : Number.MAX_SAFE_INTEGER;
          const bMs = b?.expiresAt?.seconds ? b.expiresAt.seconds * 1000 : Number.MAX_SAFE_INTEGER;
          return aMs - bMs;
        })
        .slice(0, 6);

      setStats({
        pending: pendingBookings.length,
        booked: bookedBookings.length,
        expiringSoon,
        overdue,
        openZones,
      });
      setRecentPending(sortedPending);
    } catch (error) {
      console.error('Error loading security overview:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSecurityOverview();
  }, []);

  return (
    <div style={{ display: 'grid', gap: '1.5rem' }}>
      <div className="glass" style={{ borderRadius: '1.25rem', padding: '1.5rem', border: '1px solid var(--border)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem', flexWrap: 'wrap' }}>
          <div>
            <p style={{ margin: 0, color: 'var(--muted)', fontWeight: 700, fontSize: '0.8rem', letterSpacing: '0.08em' }}>SECURITY OVERVIEW</p>
            <h3 style={{ margin: '0.5rem 0 0', fontSize: '1.6rem', fontWeight: 900 }}>Gate & Parking Situation Room</h3>
            <p style={{ margin: '0.6rem 0 0', color: 'var(--muted)' }}>Live queue, expiring requests, and one-click access to parking control.</p>
          </div>
          <button
            onClick={loadSecurityOverview}
            disabled={loading}
            style={{
              border: '1px solid var(--border)',
              background: 'rgba(255,255,255,0.03)',
              color: 'white',
              borderRadius: '0.75rem',
              padding: '0.6rem 0.9rem',
              fontWeight: 700,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <RefreshCcw size={16} /> {loading ? 'Syncing...' : 'Refresh'}
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem' }}>
        <MetricCard icon={<Clock size={18} />} label="Pending Queue" value={stats.pending} tone="#f59e0b" />
        <MetricCard icon={<CheckCircle2 size={18} />} label="Booked Slots" value={stats.booked} tone="#14b8a6" />
        <MetricCard icon={<ShieldAlert size={18} />} label="Expiring Soon" value={stats.expiringSoon} tone="#fb923c" />
        <MetricCard icon={<Activity size={18} />} label="Overdue" value={stats.overdue} tone="#f43f5e" />
        <MetricCard icon={<Car size={18} />} label="Open Zones" value={stats.openZones} tone="#38bdf8" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '1rem' }}>
        <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
          <h4 style={{ margin: '0 0 1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Activity size={18} /> Security Operations Board
          </h4>
          <div style={{ display: 'grid', gap: '0.8rem' }}>
            <PriorityItem title="Pending confirmations" value={stats.pending} detail={stats.pending > 0 ? 'Move pending slots to booked quickly.' : 'No pending slots right now.'} tone={stats.pending > 0 ? '#f59e0b' : '#22c55e'} />
            <PriorityItem title="Urgent expiring requests" value={stats.expiringSoon} detail="These bookings may auto-expire within 5 minutes." tone="#fb923c" />
            <PriorityItem title="Overdue queue" value={stats.overdue} detail="Review overdue pending records and clear where needed." tone={stats.overdue > 0 ? '#f43f5e' : '#22c55e'} />
          </div>

          <div style={{ marginTop: '1rem', display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '0.8rem' }}>
            <QuickLinkCard to="/dashboard/parking" title="Parking Control" desc="Open live slot grid" icon={<Car size={16} />} />
            <QuickLinkCard to="/dashboard" title="Security Home" desc="Refresh live overview" icon={<BarChart3 size={16} />} />
          </div>
        </div>

        <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
          <h4 style={{ margin: '0 0 1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Clock size={18} /> Pending Priority Queue
          </h4>
          <div style={{ display: 'grid', gap: '0.7rem' }}>
            {recentPending.length === 0 && <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No pending records at the moment.</div>}
            {recentPending.map((item) => (
              <div key={item.id} style={{ padding: '0.7rem 0.8rem', background: 'rgba(255,255,255,0.03)', borderRadius: '0.7rem', border: '1px solid var(--border)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.7rem', alignItems: 'baseline' }}>
                  <div style={{ fontWeight: 800 }}>{(item.spotId || item.id || 'UNKNOWN').toUpperCase()}</div>
                  <span style={{ color: '#fbbf24', fontSize: '0.75rem', fontWeight: 800 }}>{getRemainingLabel(item)}</span>
                </div>
                <div style={{ marginTop: '0.2rem', color: 'var(--muted)', fontSize: '0.8rem' }}>{item.studentEmail || 'Unknown student'}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

        function AdminOverview() {
          const [loading, setLoading] = useState(true);
          const [stats, setStats] = useState({
            totalUsers: 0,
            activeStaff: 0,
            pendingOrders: 0,
            availableParkingZones: 0,
            totalNews: 0,
          });
          const [latestNews, setLatestNews] = useState([]);
          const [recentUsers, setRecentUsers] = useState([]);
          const [recentOrders, setRecentOrders] = useState([]);
          const [parkingZones, setParkingZones] = useState([]);
          const [roleBreakdown, setRoleBreakdown] = useState([]);

          const sortByCreatedAt = (items) =>
            [...items].sort((a, b) => {
              const left = a.createdAt?.toMillis?.() || 0;
              const right = b.createdAt?.toMillis?.() || 0;
              return right - left;
            });

          const loadOverview = async () => {
            setLoading(true);
            try {
              const [usersSnap, newsSnap, ordersSnap, parkingSnap] = await Promise.all([
                getDocs(collection(db, 'users')),
                getDocs(collection(db, 'news')),
                getDocs(collection(db, 'orders')),
                getDocs(collection(db, 'parking')),
              ]);

              const users = sortByCreatedAt(usersSnap.docs.map((d) => ({ id: d.id, ...d.data() })));
              const news = sortByCreatedAt(newsSnap.docs.map((d) => ({ id: d.id, ...d.data() })));
              const orders = sortByCreatedAt(ordersSnap.docs.map((d) => ({ id: d.id, ...d.data() })));
              const parking = parkingSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

              const activeStaffCount = users.filter((u) => ['admin', 'security', 'cafeteria_manager'].includes(u.role)).length;
              const pendingOrders = orders.filter((o) => ['Pending', 'Preparing'].includes(o.status));
              const availableParkingCount = parking.filter((p) => Number(p.availableSlots || 0) > 0).length;
              const roleMap = users.reduce((acc, item) => {
                const role = item.role || 'unassigned';
                acc[role] = (acc[role] || 0) + 1;
                return acc;
              }, {});

              setStats({
                totalUsers: users.length,
                activeStaff: activeStaffCount,
                pendingOrders: pendingOrders.length,
                availableParkingZones: availableParkingCount,
                totalNews: news.length,
              });

              setLatestNews(news.slice(0, 3));
              setRecentUsers(users.slice(0, 4));
              setRecentOrders(orders.slice(0, 4));
              setParkingZones(parking);
              setRoleBreakdown(Object.entries(roleMap).map(([role, count]) => ({ role, count })));
            } catch (error) {
              console.error('Error loading admin overview:', error);
            } finally {
              setLoading(false);
            }
          };

          useEffect(() => {
            loadOverview();
          }, []);

          return (
            <div style={{ display: 'grid', gap: '1.5rem' }}>
              <div className="glass" style={{ borderRadius: '1.25rem', padding: '1.5rem', border: '1px solid var(--border)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem', flexWrap: 'wrap' }}>
                  <div>
                    <p style={{ margin: 0, color: 'var(--muted)', fontWeight: 700, fontSize: '0.8rem', letterSpacing: '0.08em' }}>SHS ADMIN DASHBOARD</p>
                    <h3 style={{ margin: '0.5rem 0 0', fontSize: '1.6rem', fontWeight: 900 }}>Smart Hub Status Center</h3>
                    <p style={{ margin: '0.6rem 0 0', color: 'var(--muted)' }}>Live campus operations, bottlenecks, and actions that need attention now.</p>
                  </div>
                  <button
                    onClick={loadOverview}
                    disabled={loading}
                    style={{
                      border: '1px solid var(--border)',
                      background: 'rgba(255,255,255,0.03)',
                      color: 'white',
                      borderRadius: '0.75rem',
                      padding: '0.6rem 0.9rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}
                  >
                    <RefreshCcw size={16} /> {loading ? 'Syncing...' : 'Refresh'}
                  </button>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, minmax(0, 1fr))', gap: '1rem' }}>
                <MetricCard icon={<Users size={18} />} label="Total Users" value={stats.totalUsers} tone="#8b5cf6" />
                <MetricCard icon={<ShieldAlert size={18} />} label="Active Staff" value={stats.activeStaff} tone="#14b8a6" />
                <MetricCard icon={<Utensils size={18} />} label="Pending Orders" value={stats.pendingOrders} tone="#f59e0b" />
                <MetricCard icon={<Car size={18} />} label="Open Parking" value={stats.availableParkingZones} tone="#38bdf8" />
                <MetricCard icon={<Newspaper size={18} />} label="News Posts" value={stats.totalNews} tone="#f43f5e" />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '1rem' }}>
                <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
                  <h4 style={{ margin: '0 0 1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Activity size={18} /> Operations Board
                  </h4>
                  <div style={{ display: 'grid', gap: '0.8rem' }}>
                    <PriorityItem title="Orders needing attention" value={stats.pendingOrders} detail={stats.pendingOrders > 0 ? 'Prepare or clear the queue.' : 'No live orders waiting right now.'} tone={stats.pendingOrders > 0 ? '#f59e0b' : '#22c55e'} />
                    <PriorityItem title="Parking coverage" value={`${stats.availableParkingZones}/${parkingZones.length}`} detail={parkingZones.length > 0 ? 'Zones have availability online.' : 'Parking data is still loading.'} tone="#38bdf8" />
                    <PriorityItem title="Active staff coverage" value={stats.activeStaff} detail="Admin, security, and cafeteria teams counted from live user records." tone="#14b8a6" />
                  </div>

                  <div style={{ marginTop: '1rem', display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '0.8rem' }}>
                    <QuickLinkCard to="/dashboard/users" title="User Registry" desc="Manage campus accounts" icon={<Users size={16} />} />
                    <QuickLinkCard to="/dashboard/news" title="News Control" desc="Publish and review updates" icon={<Newspaper size={16} />} />
                    <QuickLinkCard to="/dashboard/parking" title="Parking Control" desc="Live slot monitoring" icon={<Car size={16} />} />
                    <QuickLinkCard to="/dashboard/orders" title="Kitchen Queue" desc="Track active service orders" icon={<Utensils size={16} />} />
                  </div>
                </div>

                <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
                  <h4 style={{ margin: '0 0 1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <BarChart3 size={18} /> Role Breakdown
                  </h4>
                  <div style={{ display: 'grid', gap: '0.8rem' }}>
                    {roleBreakdown.length === 0 && <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No roles found yet.</div>}
                    {roleBreakdown.map((entry) => {
                      const total = Math.max(stats.totalUsers, 1);
                      const percent = Math.round((entry.count / total) * 100);
                      return (
                        <div key={entry.role}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.35rem', fontWeight: 700, fontSize: '0.85rem' }}>
                            <span>{entry.role.replace('_', ' ')}</span>
                            <span>{entry.count} ({percent}%)</span>
                          </div>
                          <div style={{ height: '8px', borderRadius: '999px', background: 'rgba(255,255,255,0.06)', overflow: 'hidden' }}>
                            <div style={{ width: `${percent}%`, height: '100%', background: 'linear-gradient(90deg, #8b5cf6, #14b8a6)' }} />
                          </div>
                        </div>
                      );
                    })}
                  </div>

                  <h4 style={{ margin: '1.25rem 0 1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Clock size={18} /> Latest News Activity
                  </h4>
                  <div style={{ display: 'grid', gap: '0.7rem' }}>
                    {latestNews.length === 0 && <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No posts available yet.</div>}
                    {latestNews.map((item) => (
                      <div key={item.id} style={{ padding: '0.7rem 0.8rem', background: 'rgba(255,255,255,0.03)', borderRadius: '0.7rem', border: '1px solid var(--border)' }}>
                        <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{item.title || 'Untitled update'}</div>
                        <div style={{ color: 'var(--muted)', fontSize: '0.78rem', marginTop: '0.2rem' }}>{item.date || 'Scheduled'}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
                  <h4 style={{ margin: '0 0 1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Users size={18} /> Recent Staff Activity
                  </h4>
                  <div style={{ display: 'grid', gap: '0.65rem' }}>
                    {recentUsers.length === 0 && <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No staff records found.</div>}
                    {recentUsers.map((person) => (
                      <div key={person.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.7rem 0.8rem', background: 'rgba(255,255,255,0.03)', borderRadius: '0.7rem', border: '1px solid var(--border)' }}>
                        <div>
                          <div style={{ fontWeight: 700 }}>{person.name || 'Unnamed user'}</div>
                          <div style={{ color: 'var(--muted)', fontSize: '0.78rem' }}>{person.email || 'No email'}</div>
                        </div>
                        <span style={{ padding: '0.3rem 0.65rem', borderRadius: '999px', background: 'rgba(139,92,246,0.14)', color: '#8b5cf6', fontSize: '0.72rem', fontWeight: 800 }}>
                          {(person.role || 'unassigned').toUpperCase()}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="glass" style={{ borderRadius: '1rem', padding: '1.25rem', border: '1px solid var(--border)' }}>
                  <h4 style={{ margin: '0 0 1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Utensils size={18} /> Recent Orders
                  </h4>
                  <div style={{ display: 'grid', gap: '0.65rem' }}>
                    {recentOrders.length === 0 && <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No orders found.</div>}
                    {recentOrders.map((order) => (
                      <div key={order.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.7rem 0.8rem', background: 'rgba(255,255,255,0.03)', borderRadius: '0.7rem', border: '1px solid var(--border)' }}>
                        <div>
                          <div style={{ fontWeight: 700 }}>#{order.orderNumber || order.id}</div>
                          <div style={{ color: 'var(--muted)', fontSize: '0.78rem' }}>{order.type || 'Order'} · {Array.isArray(order.items) ? order.items.length : 0} items</div>
                        </div>
                        <span style={{ padding: '0.3rem 0.65rem', borderRadius: '999px', background: 'rgba(245,158,11,0.15)', color: '#f59e0b', fontSize: '0.72rem', fontWeight: 800 }}>
                          {(order.status || 'unknown').toUpperCase()}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div className="glass" style={{ borderRadius: '1rem', padding: '1rem 1.25rem', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', color: '#22c55e', fontWeight: 700 }}>
                  <CheckCircle2 size={18} /> Core systems are synchronized and running.
                </div>
                <div style={{ fontSize: '0.85rem', color: 'var(--muted)' }}>Last sync: {new Date().toLocaleTimeString()}</div>
              </div>
            </div>
          );
        }

        function MetricCard({ icon, label, value, tone }) {
          return (
            <div className="glass" style={{ borderRadius: '1rem', padding: '1rem', border: '1px solid var(--border)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: tone, fontWeight: 700, fontSize: '0.8rem' }}>
                {icon} {label}
              </div>
              <div style={{ marginTop: '0.5rem', fontSize: '1.8rem', fontWeight: 900 }}>{value}</div>
            </div>
          );
        }

        function QuickLinkCard({ to, title, desc, icon }) {
          return (
            <Link to={to} style={{ textDecoration: 'none', color: 'white', borderRadius: '0.8rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', padding: '0.9rem', display: 'grid', gap: '0.4rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', fontWeight: 800 }}>{icon} {title}</div>
              <div style={{ color: 'var(--muted)', fontSize: '0.82rem' }}>{desc}</div>
            </Link>
          );
        }

        function PriorityItem({ title, value, detail, tone }) {
          return (
            <div style={{ padding: '0.95rem 1rem', background: 'rgba(255,255,255,0.03)', borderRadius: '0.9rem', border: '1px solid var(--border)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.8rem', alignItems: 'baseline' }}>
                <div style={{ fontWeight: 800 }}>{title}</div>
                <div style={{ color: tone, fontSize: '1.1rem', fontWeight: 900 }}>{value}</div>
              </div>
              <div style={{ marginTop: '0.35rem', color: 'var(--muted)', fontSize: '0.84rem' }}>{detail}</div>
            </div>
          );
        }

        function LostFoundApprovals() {
          const [items, setItems] = useState([]);
          const [loading, setLoading] = useState(true);
          const [busyId, setBusyId] = useState('');
          const [error, setError] = useState('');

          useEffect(() => {
            const feedQuery = query(collection(db, 'lost_found_items'), orderBy('timestamp', 'desc'));
            const unsubscribe = onSnapshot(
              feedQuery,
              (snapshot) => {
                const mapped = snapshot.docs.map((docItem) => ({ id: docItem.id, ...docItem.data() }));
                const pendingOnly = mapped.filter((item) => String(item.approvalStatus || '').toLowerCase() === 'pending');
                setItems(pendingOnly);
                setLoading(false);
              },
              (snapshotError) => {
                setError(snapshotError?.message || 'Failed to load pending reports.');
                setLoading(false);
              }
            );

            return () => unsubscribe();
          }, []);

          const handleApprove = async (item) => {
            setBusyId(item.id);
            setError('');
            try {
              await updateDoc(doc(db, 'lost_found_items', item.id), {
                approvalStatus: 'approved',
                approvedByAdmin: true,
                approvedAt: serverTimestamp(),
              });

              const type = item.type === 'lost' ? 'lost' : 'found';
              const itemName = item.name || 'item';
              const itemLoc = item.location || 'campus';
              const itemDesc = item.description || '';
              const itemStatus = item.itemStatus || '';
              const userName = item.reportedBy || 'Student';
              const userEmail = item.reportedByEmail || 'student@unilink.com';

              await addDoc(collection(db, 'unifeed_posts'), {
                type: 'post',
                authorName: `${userName} (Lost & Found)`,
                authorEmail: userEmail,
                content:
                  type === 'lost'
                    ? `I lost my ${itemName} at ${itemLoc}. Please help me find it!\nDetails: ${itemDesc}`
                    : `I found a ${itemName} at ${itemLoc}. I left it at ${itemStatus === 'at_guard_room' ? 'the Security Guard Room' : `the ${String(itemStatus).replace('at_faculty_', '')} Faculty Office`}.\nDetails: ${itemDesc}`,
                status: 'approved',
                timestamp: serverTimestamp(),
                likes: [],
                commentsList: [],
                shares: 0,
              });
            } catch (approveError) {
              setError(approveError?.message || 'Failed to approve report.');
            } finally {
              setBusyId('');
            }
          };

          const handleReject = async (id) => {
            setBusyId(id);
            setError('');
            try {
              await deleteDoc(doc(db, 'lost_found_items', id));
            } catch (rejectError) {
              setError(rejectError?.message || 'Failed to reject report.');
            } finally {
              setBusyId('');
            }
          };

          if (loading) {
            return <div className="card glass">Loading pending lost & found reports...</div>;
          }

          return (
            <div className="card glass" style={{ maxWidth: '1050px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
                <div>
                  <h3 style={{ margin: 0, fontWeight: 900 }}>Lost & Found Approvals</h3>
                  <p style={{ margin: '0.35rem 0 0', color: 'var(--muted)', fontSize: '0.85rem' }}>
                    Pending reports from students waiting for admin approval.
                  </p>
                </div>
                <span style={{ padding: '0.35rem 0.7rem', borderRadius: '999px', background: 'rgba(245, 158, 11, 0.15)', color: '#f59e0b', fontWeight: 800, fontSize: '0.78rem' }}>
                  {items.length} Pending
                </span>
              </div>

              {error && (
                <div style={{ marginBottom: '0.85rem', color: '#f87171', fontWeight: 700 }}>{error}</div>
              )}

              {items.length === 0 ? (
                <div style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>No pending lost/found reports right now.</div>
              ) : (
                <div style={{ display: 'grid', gap: '0.8rem' }}>
                  {items.map((item) => {
                    const status = String(item.itemStatus || '').toUpperCase();
                    const isBusy = busyId === item.id;
                    return (
                      <div key={item.id} style={{ border: '1px solid var(--border)', borderRadius: '0.85rem', padding: '0.85rem 0.95rem', background: 'rgba(255,255,255,0.02)' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.8rem', alignItems: 'flex-start' }}>
                          <div>
                            <div style={{ fontWeight: 800, fontSize: '1rem' }}>[{String(item.type || 'item').toUpperCase()}] {item.name || 'Unnamed item'}</div>
                            <div style={{ marginTop: '0.35rem', color: 'var(--muted)', fontSize: '0.84rem' }}>{item.description || 'No description'}</div>
                            <div style={{ marginTop: '0.35rem', color: 'var(--muted)', fontSize: '0.8rem' }}>
                              Location: {item.location || 'Unknown'} · Status: {status || 'N/A'}
                            </div>
                            <div style={{ marginTop: '0.2rem', color: 'var(--muted)', fontSize: '0.78rem' }}>
                              Reported by: {item.reportedBy || item.reportedByEmail || 'Student'}
                            </div>
                          </div>
                          <div style={{ display: 'flex', gap: '0.55rem' }}>
                            <button
                              onClick={() => handleReject(item.id)}
                              disabled={isBusy}
                              style={{ padding: '0.5rem 0.8rem', borderRadius: '0.6rem', border: '1px solid #ef4444', color: '#f87171', background: 'transparent', fontWeight: 700, cursor: 'pointer' }}
                            >
                              Reject
                            </button>
                            <button
                              onClick={() => handleApprove(item)}
                              disabled={isBusy}
                              className="btn-primary"
                              style={{ minWidth: '90px' }}
                            >
                              {isBusy ? 'Saving...' : 'Approve'}
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          );
        }

function AdminNews() {
  const [form, setForm] = useState({ title: '', subtitle: '', imageUrl: '', date: '' });
  const [loading, setLoading] = useState(false);

  const handleAddNews = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await addDoc(collection(db, 'news'), {
        ...form,
        createdAt: serverTimestamp()
      });
      alert('News posted successfully!');
      setForm({ title: '', subtitle: '', imageUrl: '', date: '' });
    } catch (err) {
      alert('Failed to post news');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '800px' }}>
      <div className="card glass" style={{ marginBottom: '2rem' }}>
        <h3 style={{ marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Plus size={20} /> Create Campus News</h3>
        <form onSubmit={handleAddNews} style={{ display: 'grid', gap: '1.25rem' }}>
          <input 
            placeholder="Main Title" 
            className="input-field"
            value={form.title}
            onChange={(e) => setForm({...form, title: e.target.value})}
            required
            style={{ width: '100%', padding: '0.75rem', background: '#0f172a', border: '1px solid var(--border)', borderRadius: '0.75rem', color: 'white' }}
          />
          <input 
            placeholder="Short Subtitle" 
            className="input-field"
            value={form.subtitle}
            onChange={(e) => setForm({...form, subtitle: e.target.value})}
            required
            style={{ width: '100%', padding: '0.75rem', background: '#0f172a', border: '1px solid var(--border)', borderRadius: '0.75rem', color: 'white' }}
          />
          <input 
            placeholder="Image URL" 
            className="input-field"
            value={form.imageUrl}
            onChange={(e) => setForm({...form, imageUrl: e.target.value})}
            style={{ width: '100%', padding: '0.75rem', background: '#0f172a', border: '1px solid var(--border)', borderRadius: '0.75rem', color: 'white' }}
          />
          <input 
            placeholder="Date (e.g., MAY 01)" 
            className="input-field"
            value={form.date}
            onChange={(e) => setForm({...form, date: e.target.value})}
            required
            style={{ width: '100%', padding: '0.75rem', background: '#0f172a', border: '1px solid var(--border)', borderRadius: '0.75rem', color: 'white' }}
          />
          <button className="btn-primary" disabled={loading} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem' }}>
            <Send size={18} /> {loading ? 'Posting...' : 'Push Update'}
          </button>
        </form>
      </div>
    </div>
  );
}

function ParkingManager() {
  const [slots, setSlots] = useState([]);
  const [bookingSlots, setBookingSlots] = useState([]);
  const currentUser = JSON.parse(localStorage.getItem('user') || '{}');
  const isSecurityUser = currentUser?.role === 'security';
  const canManageParkingBookings =
    currentUser?.role === 'security' || currentUser?.role === 'admin';
  const [selectedVehicleType, setSelectedVehicleType] = useState('car');
  const [selectedZone, setSelectedZone] = useState(0);
  const [selectedSlotId, setSelectedSlotId] = useState('');
  const [manualStudentEmail, setManualStudentEmail] = useState('');
  const [bookingBusy, setBookingBusy] = useState(false);
  const [showQuickBookingModal, setShowQuickBookingModal] = useState(false);
  const [quickBookingEmail, setQuickBookingEmail] = useState('');
  const [pendingWaitMessage, setPendingWaitMessage] = useState('');

  const carSpotIds = Array.from({ length: 150 }, (_, index) => `C-${String(index + 1).padStart(3, '0')}`);
  const bikeSpotIds = Array.from({ length: 100 }, (_, index) => `B-${String(index + 1).padStart(3, '0')}`);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'parking'), (snapshot) => {
      const slotsList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setSlots(slotsList);
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    const unsubBookings = onSnapshot(collection(db, 'parking_bookings'), (snapshot) => {
      const bookings = snapshot.docs
        .map((docItem) => ({ id: docItem.id, ...docItem.data() }))
        .sort((a, b) => {
          const aSeconds = a?.timestamp?.seconds ?? 0;
          const bSeconds = b?.timestamp?.seconds ?? 0;
          return bSeconds - aSeconds;
        });
      setBookingSlots(bookings);
    });

    return () => unsubBookings();
  }, []);

  useEffect(() => {
    const cleanupExpiredPending = async () => {
      const nowMs = Date.now();
      const expiredPending = bookingSlots.filter((booking) => {
        const status = (booking.status || '').toLowerCase();
        const expiresAtMs = booking?.expiresAt?.seconds
          ? booking.expiresAt.seconds * 1000
          : null;
        return status === 'pending' && expiresAtMs !== null && expiresAtMs <= nowMs;
      });

      if (expiredPending.length === 0) return;

      await Promise.all(
        expiredPending.map((booking) => deleteDoc(doc(db, 'parking_bookings', booking.spotId || booking.id)))
      );
    };

    cleanupExpiredPending();
  }, [bookingSlots]);

  const updateSlots = async (id, currentAvailable, delta) => {
    const newVal = currentAvailable + delta;
    if (newVal < 0) return;
    try {
      const slotRef = doc(db, 'parking', id);
      await updateDoc(slotRef, { availableSlots: newVal });
    } catch (err) {
      alert('Failed to update parking');
    }
  };

  const getCurrentTimeLabel = () => {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  };

  const createOrUpdateBooking = async ({ spotId, status, studentEmail, source }) => {
    if (!spotId) return false;

    const bookingAt = new Date();
    const expiresAt = new Date(bookingAt.getTime() + 30 * 60 * 1000);
    const normalizedStudentEmail = (studentEmail || 'student@unilink.com').trim().toLowerCase();

    try {
      setBookingBusy(true);

      const existingActiveBookingSnapshot = await getDocs(
        query(
          collection(db, 'parking_bookings'),
          where('studentEmail', '==', normalizedStudentEmail),
          where('status', 'in', ['pending', 'booked'])
        )
      );

      const activeBooking = existingActiveBookingSnapshot.docs.find(
        (bookingDoc) => (bookingDoc.data()?.spotId || bookingDoc.id) !== spotId
      );

      if (activeBooking) {
        alert(
          `That student already has an active booking for ${activeBooking.data()?.spotId || activeBooking.id}. Free it first before creating another slot.`
        );
        return false;
      }

      await setDoc(
        doc(db, 'parking_bookings', spotId),
        {
          spotId,
          status,
          studentEmail: normalizedStudentEmail,
          arrivalTime: getCurrentTimeLabel(),
          bookingAt: Timestamp.fromDate(bookingAt),
          expiresAt: Timestamp.fromDate(expiresAt),
          timestamp: serverTimestamp(),
          source,
          updatedBy: currentUser?.email || currentUser?.role || 'staff',
        },
        { merge: true }
      );
      setSelectedSlotId('');
      setManualStudentEmail('');
      return true;
    } catch (err) {
      const errMsg = err?.message || 'Failed to save booking';
      alert(errMsg);
      return false;
    } finally {
      setBookingBusy(false);
    }
  };

  const openQuickBookingDialog = (spotId) => {
    setSelectedSlotId(spotId);
    setQuickBookingEmail('');
    setShowQuickBookingModal(true);
  };

  const handleQuickPendingBooking = async () => {
    const success = await createOrUpdateBooking({
      spotId: selectedSlotId,
      status: 'pending',
      studentEmail: quickBookingEmail,
      source: 'grid-quick-booking',
    });

    if (success) {
      setPendingWaitMessage(
        `Slot ${selectedSlotId} is pending and waiting for security confirmation.`
      );
      setShowQuickBookingModal(false);
      setQuickBookingEmail('');
      setSelectedSlotId('');
    }
  };

  const handleQuickConfirmedBooking = async () => {
    const success = await createOrUpdateBooking({
      spotId: selectedSlotId,
      status: 'booked',
      studentEmail: quickBookingEmail,
      source: 'grid-quick-confirmed',
    });

    if (success) {
      setPendingWaitMessage(
        `Slot ${selectedSlotId} is now confirmed as BOOKED.`
      );
      setShowQuickBookingModal(false);
      setQuickBookingEmail('');
      setSelectedSlotId('');
    }
  };

  const handleGridSlotClick = async (spotId, status) => {
    if (status === 'available') {
      openQuickBookingDialog(spotId);
      return;
    }

    if (status === 'pending') {
      if (!canManageParkingBookings) {
        setPendingWaitMessage(
          `Slot ${spotId} is pending and waiting for security confirmation.`
        );
        return;
      }

      setBookingBusy(true);
      try {
        await updateBookingStatus(spotId, 'booked');
        setPendingWaitMessage(`Slot ${spotId} pending booking confirmed.`);
      } finally {
        setBookingBusy(false);
      }
      return;
    }

    if (status === 'booked') {
      setPendingWaitMessage(`Slot ${spotId} is already booked.`);
    }
  };

  const updateBookingStatus = async (spotId, status) => {
    try {
      await updateDoc(doc(db, 'parking_bookings', spotId), {
        status,
        timestamp: serverTimestamp(),
        updatedBy: currentUser?.email || currentUser?.role || 'staff',
      });
      return true;
    } catch (err) {
      alert('Failed to update booking status');
      return false;
    }
  };

  const clearBooking = async (spotId) => {
    try {
      await deleteDoc(doc(db, 'parking_bookings', spotId));
    } catch (err) {
      alert('Failed to clear booking');
    }
  };

  const freeBooking = async (spotId) => {
    try {
      await deleteDoc(doc(db, 'parking_bookings', spotId));
      setPendingWaitMessage(`Slot ${spotId} was freed.`);
    } catch (err) {
      alert('Failed to free slot');
    }
  };

  const activeStudentSlots = bookingSlots.filter((booking) => {
    const status = (booking.status || '').toLowerCase();
    return status === 'pending' || status === 'booked';
  });

  const pendingBookings = bookingSlots.filter(
    (booking) => (booking.status || '').toLowerCase() === 'pending'
  );
  const nowMs = Date.now();
  const pendingExpiringSoonCount = pendingBookings.filter((booking) => {
    const expiresAtMs = booking?.expiresAt?.seconds
      ? booking.expiresAt.seconds * 1000
      : null;
    if (!expiresAtMs) return false;
    const remainingMs = expiresAtMs - nowMs;
    return remainingMs > 0 && remainingMs <= 5 * 60 * 1000;
  }).length;
  const pendingOverdueCount = pendingBookings.filter((booking) => {
    const expiresAtMs = booking?.expiresAt?.seconds
      ? booking.expiresAt.seconds * 1000
      : null;
    return expiresAtMs !== null && expiresAtMs <= nowMs;
  }).length;
  const bookedCount = bookingSlots.filter(
    (booking) => (booking.status || '').toLowerCase() === 'booked'
  ).length;
  const completedCount = bookingSlots.filter(
    (booking) => (booking.status || '').toLowerCase() === 'completed'
  ).length;
  const nextPendingBooking = [...pendingBookings]
    .sort((a, b) => {
      const aMs = a?.expiresAt?.seconds ? a.expiresAt.seconds * 1000 : Number.MAX_SAFE_INTEGER;
      const bMs = b?.expiresAt?.seconds ? b.expiresAt.seconds * 1000 : Number.MAX_SAFE_INTEGER;
      return aMs - bMs;
    })[0] || null;

  const handleConfirmNextPending = async () => {
    if (!nextPendingBooking?.spotId) {
      setPendingWaitMessage('No pending bookings to confirm right now.');
      return;
    }

    setBookingBusy(true);
    try {
      const ok = await updateBookingStatus(nextPendingBooking.spotId, 'booked');
      if (ok) {
        setPendingWaitMessage(`Confirmed next pending slot: ${nextPendingBooking.spotId}.`);
      }
    } finally {
      setBookingBusy(false);
    }
  };

  const getPendingRemainingLabel = (booking) => {
    const expiresAtMs = booking?.expiresAt?.seconds
      ? booking.expiresAt.seconds * 1000
      : null;
    if (!expiresAtMs) return 'No expiry time';

    const remainingMs = expiresAtMs - Date.now();
    if (remainingMs <= 0) return 'Expired';

    const remainingMinutes = Math.ceil(remainingMs / 60000);
    return `Expires in ${remainingMinutes} min`;
  };

  const completedStudentSlots = bookingSlots.filter(
    (booking) => (booking.status || '').toLowerCase() === 'completed'
  );

  const bookingStatusMap = bookingSlots.reduce((acc, booking) => {
    const slotId = (booking.spotId || booking.id || '').toUpperCase();
    if (slotId.startsWith('C-') || slotId.startsWith('B-')) {
      acc[slotId] = (booking.status || 'available').toLowerCase();
    }
    return acc;
  }, {});

  const vehicleSpots = selectedVehicleType === 'car' ? carSpotIds : bikeSpotIds;
  const spotsPerZone = selectedVehicleType === 'car' ? 50 : 100;
  const zoneCount = Math.max(1, Math.ceil(vehicleSpots.length / spotsPerZone));
  const zoneStart = selectedZone * spotsPerZone;
  const zoneEnd = Math.min(zoneStart + spotsPerZone, vehicleSpots.length);
  const visibleSpots = vehicleSpots.slice(zoneStart, zoneEnd);
  const visibleStatusCounts = visibleSpots.reduce(
    (acc, spotId) => {
      const status = (bookingStatusMap[spotId] || 'available').toLowerCase();
      if (status === 'pending') {
        acc.pending += 1;
      } else if (status === 'booked') {
        acc.booked += 1;
      } else {
        acc.available += 1;
      }
      return acc;
    },
    { available: 0, pending: 0, booked: 0 }
  );

  const spotStatusMeta = (spotId) => {
    const status = bookingStatusMap[spotId] || 'available';

    if (status === 'pending') {
      return {
        status,
        border: '#f59e0b',
        bg: 'rgba(245, 158, 11, 0.12)',
        text: '#fbbf24',
      };
    }

    if (status === 'booked') {
      return {
        status,
        border: '#14b8a6',
        bg: 'rgba(20, 184, 166, 0.12)',
        text: '#2dd4bf',
      };
    }

    return {
      status: 'available',
      border: '#22c55e',
      bg: 'rgba(34, 197, 94, 0.12)',
      text: '#4ade80',
    };
  };

  const renderSlotRow = (booking) => {
    const status = (booking.status || 'available').toLowerCase();
    const slotId = (booking.spotId || booking.id || '').toUpperCase();
    const statusTone =
      status === 'pending'
        ? '#f59e0b'
        : status === 'booked'
          ? '#14b8a6'
          : status === 'completed'
            ? '#38bdf8'
            : '#94a3b8';

    return (
      <div
        key={booking.id}
        style={{
          border: `1px solid ${statusTone}55`,
          borderRadius: '0.85rem',
          padding: '0.85rem',
          background: 'rgba(15, 23, 42, 0.45)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          gap: '0.75rem',
        }}
      >
        <div style={{ minWidth: 0 }}>
          <div style={{ fontWeight: 800 }}>Spot: {slotId}</div>
          <div style={{ fontSize: '0.8rem', color: 'var(--muted)', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {booking.studentEmail || 'Unknown student'}
          </div>
          {status === 'pending' && (
            <div style={{ marginTop: '0.2rem', fontSize: '0.72rem', color: '#fbbf24', fontWeight: 700 }}>
              {getPendingRemainingLabel(booking)}
            </div>
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          <span
            style={{
              padding: '0.3rem 0.6rem',
              borderRadius: '999px',
              fontSize: '0.7rem',
              fontWeight: 800,
              color: statusTone,
              background: `${statusTone}22`,
              border: `1px solid ${statusTone}55`,
              whiteSpace: 'nowrap',
            }}
          >
            {status.toUpperCase()}
          </span>
          {canManageParkingBookings && status === 'pending' && (
            <button
              onClick={() => updateBookingStatus(slotId, 'booked')}
              style={{ padding: '0.35rem 0.6rem', borderRadius: '0.5rem', border: '1px solid #14b8a655', background: '#14b8a622', color: '#2dd4bf', fontWeight: 700, cursor: 'pointer', fontSize: '0.72rem' }}
            >
              Confirm Book
            </button>
          )}
          {canManageParkingBookings && status === 'booked' && (
            <button
              onClick={() => updateBookingStatus(slotId, 'completed')}
              style={{ padding: '0.35rem 0.6rem', borderRadius: '0.5rem', border: '1px solid #38bdf855', background: '#38bdf822', color: '#7dd3fc', fontWeight: 700, cursor: 'pointer', fontSize: '0.72rem' }}
            >
              Mark Exit
            </button>
          )}
          {canManageParkingBookings && (status === 'pending' || status === 'booked' || status === 'completed') && (
            <button
              onClick={() => freeBooking(slotId)}
              style={{ padding: '0.35rem 0.6rem', borderRadius: '0.5rem', border: '1px solid #f59e0b55', background: '#f59e0b22', color: '#fbbf24', fontWeight: 700, cursor: 'pointer', fontSize: '0.72rem' }}
            >
              Free Slot
            </button>
          )}
          {canManageParkingBookings && status === 'completed' && (
            <button
              onClick={() => clearBooking(slotId)}
              style={{ padding: '0.35rem 0.6rem', borderRadius: '0.5rem', border: '1px solid #94a3b855', background: '#94a3b822', color: '#cbd5e1', fontWeight: 700, cursor: 'pointer', fontSize: '0.72rem' }}
            >
              Clear
            </button>
          )}
        </div>
      </div>
    );
  };

  return (
    <div>
      <div className="glass" style={{ borderRadius: '1.25rem', padding: '1.25rem', border: '1px solid var(--border)', marginBottom: '1rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem', flexWrap: 'wrap' }}>
          <div>
            <p style={{ margin: 0, color: 'var(--muted)', fontWeight: 700, fontSize: '0.8rem', letterSpacing: '0.08em' }}>SECURITY DASHBOARD</p>
            <h3 style={{ margin: '0.45rem 0 0', fontSize: '1.45rem', fontWeight: 900 }}>Live Parking Command Center</h3>
            <p style={{ margin: '0.55rem 0 0', color: 'var(--muted)' }}>Monitor pending requests, confirm high-priority bookings, and clear completed slots quickly.</p>
          </div>
          <div style={{ padding: '0.55rem 0.85rem', borderRadius: '0.8rem', border: '1px solid #334155', background: 'rgba(15, 23, 42, 0.45)', fontSize: '0.76rem', color: '#cbd5e1', fontWeight: 700 }}>
            Next Pending: <span style={{ color: '#fbbf24' }}>{nextPendingBooking?.spotId || 'None'}</span>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', marginBottom: '1rem' }}>
        <MetricCard icon={<Clock size={18} />} label="Pending" value={pendingBookings.length} tone="#f59e0b" />
        <MetricCard icon={<CheckCircle2 size={18} />} label="Booked" value={bookedCount} tone="#14b8a6" />
        <MetricCard icon={<Activity size={18} />} label="Active Queue" value={activeStudentSlots.length} tone="#38bdf8" />
        <MetricCard icon={<RefreshCcw size={18} />} label="Completed" value={completedCount} tone="#8b5cf6" />
      </div>

      <div
        className="card glass"
        style={{
          marginTop: '0.25rem',
          marginBottom: '1rem',
          padding: '1rem 1.1rem',
          background: 'linear-gradient(135deg, rgba(15, 23, 42, 0.88), rgba(15, 23, 42, 0.68))',
          border: '1px solid rgba(148, 163, 184, 0.22)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '0.9rem', flexWrap: 'wrap' }}>
          <div>
            <div style={{ fontSize: '0.72rem', fontWeight: 800, color: '#94a3b8', letterSpacing: '0.08em' }}>SECURITY LIVE DESK</div>
            <div style={{ marginTop: '0.2rem', fontSize: '1rem', fontWeight: 900 }}>Parking Control Snapshot</div>
          </div>
          <div style={{ display: 'flex', gap: '0.45rem', flexWrap: 'wrap' }}>
            <button
              onClick={handleConfirmNextPending}
              disabled={!nextPendingBooking || bookingBusy}
              style={{ padding: '0.42rem 0.75rem', borderRadius: '999px', border: '1px solid #14b8a655', background: '#14b8a622', color: '#5eead4', fontWeight: 800, cursor: !nextPendingBooking || bookingBusy ? 'not-allowed' : 'pointer', fontSize: '0.74rem' }}
            >
              {bookingBusy ? 'Confirming...' : 'Confirm Next Pending'}
            </button>
            <button
              onClick={() => setSelectedSlotId('')}
              style={{ padding: '0.42rem 0.75rem', borderRadius: '999px', border: '1px solid #334155', background: 'rgba(15, 23, 42, 0.55)', color: '#cbd5e1', fontWeight: 700, cursor: 'pointer', fontSize: '0.74rem' }}
            >
              Clear Selection
            </button>
            <button
              onClick={() => setPendingWaitMessage('')}
              style={{ padding: '0.42rem 0.75rem', borderRadius: '999px', border: '1px solid #334155', background: 'rgba(15, 23, 42, 0.55)', color: '#cbd5e1', fontWeight: 700, cursor: 'pointer', fontSize: '0.74rem' }}
            >
              Clear Message
            </button>
          </div>
        </div>

        {(pendingExpiringSoonCount > 0 || pendingOverdueCount > 0) && (
          <div style={{ marginTop: '0.65rem', display: 'flex', gap: '0.45rem', flexWrap: 'wrap' }}>
            {pendingExpiringSoonCount > 0 && (
              <span style={{ padding: '0.35rem 0.65rem', borderRadius: '999px', border: '1px solid #f59e0b66', background: '#f59e0b22', color: '#fbbf24', fontSize: '0.72rem', fontWeight: 800 }}>
                Expiring Soon: {pendingExpiringSoonCount}
              </span>
            )}
            {pendingOverdueCount > 0 && (
              <span style={{ padding: '0.35rem 0.65rem', borderRadius: '999px', border: '1px solid #f43f5e66', background: '#f43f5e22', color: '#fb7185', fontSize: '0.72rem', fontWeight: 800 }}>
                Overdue Pending: {pendingOverdueCount}
              </span>
            )}
          </div>
        )}

        <div style={{ marginTop: '0.75rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))', gap: '0.55rem' }}>
          <div style={{ padding: '0.58rem 0.65rem', borderRadius: '0.65rem', border: '1px solid #22c55e55', background: 'rgba(34, 197, 94, 0.11)' }}>
            <div style={{ fontSize: '0.66rem', color: '#86efac', fontWeight: 800, letterSpacing: '0.06em' }}>FREE</div>
            <div style={{ marginTop: '0.2rem', fontSize: '1.1rem', fontWeight: 900 }}>{visibleStatusCounts.available}</div>
          </div>
          <div style={{ padding: '0.58rem 0.65rem', borderRadius: '0.65rem', border: '1px solid #f59e0b55', background: 'rgba(245, 158, 11, 0.11)' }}>
            <div style={{ fontSize: '0.66rem', color: '#fcd34d', fontWeight: 800, letterSpacing: '0.06em' }}>PENDING</div>
            <div style={{ marginTop: '0.2rem', fontSize: '1.1rem', fontWeight: 900 }}>{visibleStatusCounts.pending}</div>
          </div>
          <div style={{ padding: '0.58rem 0.65rem', borderRadius: '0.65rem', border: '1px solid #14b8a655', background: 'rgba(20, 184, 166, 0.11)' }}>
            <div style={{ fontSize: '0.66rem', color: '#5eead4', fontWeight: 800, letterSpacing: '0.06em' }}>BOOKED</div>
            <div style={{ marginTop: '0.2rem', fontSize: '1.1rem', fontWeight: 900 }}>{visibleStatusCounts.booked}</div>
          </div>
          <div style={{ padding: '0.58rem 0.65rem', borderRadius: '0.65rem', border: '1px solid #38bdf855', background: 'rgba(56, 189, 248, 0.11)' }}>
            <div style={{ fontSize: '0.66rem', color: '#7dd3fc', fontWeight: 800, letterSpacing: '0.06em' }}>ACTIVE QUEUE</div>
            <div style={{ marginTop: '0.2rem', fontSize: '1.1rem', fontWeight: 900 }}>{activeStudentSlots.length}</div>
          </div>
        </div>
      </div>

      <div className="card glass" style={{ marginTop: '1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', marginBottom: '1rem', flexWrap: 'wrap' }}>
          <div>
            <h4 style={{ margin: 0, fontWeight: 900 }}>Live Slot Grid (App Style)</h4>
            <div style={{ marginTop: '0.3rem', fontSize: '0.75rem', color: '#94a3b8', fontWeight: 700 }}>
              {selectedVehicleType.toUpperCase()} | Zone {String.fromCharCode(65 + selectedZone)} | Showing {visibleSpots.length} slots
            </div>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button
              onClick={() => {
                setSelectedVehicleType('car');
                setSelectedZone(0);
              }}
              style={{
                padding: '0.45rem 0.75rem',
                borderRadius: '999px',
                border: `1px solid ${selectedVehicleType === 'car' ? '#38bdf8' : 'var(--border)'}`,
                background: selectedVehicleType === 'car' ? 'rgba(56, 189, 248, 0.16)' : 'transparent',
                color: selectedVehicleType === 'car' ? '#7dd3fc' : '#cbd5e1',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              Car Slots
            </button>
            <button
              onClick={() => {
                setSelectedVehicleType('bike');
                setSelectedZone(0);
              }}
              style={{
                padding: '0.45rem 0.75rem',
                borderRadius: '999px',
                border: `1px solid ${selectedVehicleType === 'bike' ? '#38bdf8' : 'var(--border)'}`,
                background: selectedVehicleType === 'bike' ? 'rgba(56, 189, 248, 0.16)' : 'transparent',
                color: selectedVehicleType === 'bike' ? '#7dd3fc' : '#cbd5e1',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              Bike Slots
            </button>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginBottom: '1rem' }}>
          <div style={{ padding: '0.35rem 0.7rem', borderRadius: '999px', border: '1px solid #22c55e55', background: 'rgba(34, 197, 94, 0.14)', color: '#4ade80', fontSize: '0.74rem', fontWeight: 800 }}>
            FREE {visibleStatusCounts.available}
          </div>
          <div style={{ padding: '0.35rem 0.7rem', borderRadius: '999px', border: '1px solid #f59e0b55', background: 'rgba(245, 158, 11, 0.14)', color: '#fbbf24', fontSize: '0.74rem', fontWeight: 800 }}>
            PENDING {visibleStatusCounts.pending}
          </div>
          <div style={{ padding: '0.35rem 0.7rem', borderRadius: '999px', border: '1px solid #14b8a655', background: 'rgba(20, 184, 166, 0.14)', color: '#5eead4', fontSize: '0.74rem', fontWeight: 800 }}>
            BOOKED {visibleStatusCounts.booked}
          </div>
        </div>

        {pendingWaitMessage && (
          <div style={{ marginBottom: '1rem', padding: '0.65rem 0.85rem', borderRadius: '0.7rem', border: '1px solid #f59e0b55', background: '#f59e0b22', color: '#fbbf24', fontSize: '0.78rem', fontWeight: 700 }}>
            {pendingWaitMessage}
          </div>
        )}

        <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem', flexWrap: 'wrap' }}>
          {Array.from({ length: zoneCount }, (_, zoneIndex) => (
            <button
              key={zoneIndex}
              onClick={() => setSelectedZone(zoneIndex)}
              style={{
                padding: '0.35rem 0.65rem',
                borderRadius: '999px',
                border: `1px solid ${selectedZone === zoneIndex ? '#14b8a6' : 'var(--border)'}`,
                background: selectedZone === zoneIndex ? 'rgba(20, 184, 166, 0.14)' : 'rgba(255,255,255,0.02)',
                color: selectedZone === zoneIndex ? '#5eead4' : '#94a3b8',
                fontWeight: 700,
                fontSize: '0.75rem',
                cursor: 'pointer',
              }}
            >
              Zone {String.fromCharCode(65 + zoneIndex)}
            </button>
          ))}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: selectedVehicleType === 'car' ? 'repeat(5, minmax(0, 1fr))' : 'repeat(6, minmax(0, 1fr))', gap: '0.5rem' }}>
          {visibleSpots.map((spotId) => {
            const meta = spotStatusMeta(spotId);
            const isSelected = selectedSlotId === spotId;
            const slotHint =
              meta.status === 'available'
                ? 'Tap to book'
                : meta.status === 'pending'
                  ? 'Waiting'
                  : 'Occupied';

            return (
              <div
                key={spotId}
                onClick={() => handleGridSlotClick(spotId, meta.status)}
                style={{
                  border: `1px solid ${isSelected ? '#38bdf8' : meta.border}66`,
                  background: `linear-gradient(180deg, ${meta.bg}, rgba(15, 23, 42, 0.55))`,
                  borderRadius: '0.8rem',
                  minHeight: '70px',
                  padding: '0.45rem 0.35rem',
                  boxShadow: isSelected ? '0 0 0 1px rgba(56, 189, 248, 0.35), 0 8px 16px rgba(2, 6, 23, 0.22)' : '0 6px 12px rgba(2, 6, 23, 0.16)',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '0.2rem',
                  cursor: 'pointer',
                  opacity: meta.status === 'pending' || meta.status === 'booked' ? 0.92 : 1,
                }}
              >
                <div style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 0.05rem' }}>
                  <span style={{ width: '0.42rem', height: '0.42rem', borderRadius: '999px', background: meta.text, boxShadow: `0 0 0 3px ${meta.text}22` }} />
                  <span style={{ fontSize: '0.56rem', color: meta.text, fontWeight: 800, letterSpacing: '0.08em' }}>{meta.status.toUpperCase()}</span>
                </div>
                <div style={{ fontSize: '0.74rem', fontWeight: 900, lineHeight: 1 }}>{spotId}</div>
                <div style={{ fontSize: '0.53rem', color: '#94a3b8', fontWeight: 700 }}>{slotHint}</div>
              </div>
            );
          })}
        </div>
      </div>

      {showQuickBookingModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(2, 6, 23, 0.7)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 50,
            padding: '1rem',
          }}
        >
          <div className="card glass" style={{ width: '100%', maxWidth: '460px' }}>
            <h4 style={{ margin: '0 0 0.75rem', fontWeight: 900 }}>
              {canManageParkingBookings ? 'Quick Booking / Confirm' : 'Quick Pending Booking'}
            </h4>
            <div style={{ fontSize: '0.88rem', color: '#cbd5e1', marginBottom: '0.75rem', fontWeight: 700 }}>
              Slot: <span style={{ color: '#5eead4' }}>{selectedSlotId || 'None'}</span>
            </div>
            <input
              value={quickBookingEmail}
              onChange={(e) => setQuickBookingEmail(e.target.value)}
              placeholder="Student email (optional)"
              className="input-field"
              style={{ width: '100%', padding: '0.75rem', background: '#0f172a', border: '1px solid var(--border)', borderRadius: '0.75rem', color: 'white' }}
            />
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button
                onClick={() => {
                  setShowQuickBookingModal(false);
                  setSelectedSlotId('');
                }}
                style={{ padding: '0.6rem 0.85rem', borderRadius: '0.65rem', border: '1px solid var(--border)', background: 'transparent', color: '#cbd5e1', fontWeight: 700, cursor: 'pointer' }}
              >
                Cancel
              </button>
              <button
                onClick={handleQuickPendingBooking}
                disabled={!selectedSlotId || bookingBusy}
                style={{ padding: '0.6rem 0.85rem', borderRadius: '0.65rem', border: '1px solid #f59e0b55', background: '#f59e0b22', color: '#fbbf24', fontWeight: 800, cursor: !selectedSlotId || bookingBusy ? 'not-allowed' : 'pointer' }}
              >
                {bookingBusy ? 'Saving...' : 'Create Pending'}
              </button>
              {canManageParkingBookings && (
                <button
                  onClick={handleQuickConfirmedBooking}
                  disabled={!selectedSlotId || bookingBusy}
                  style={{ padding: '0.6rem 0.85rem', borderRadius: '0.65rem', border: '1px solid #14b8a655', background: '#14b8a622', color: '#2dd4bf', fontWeight: 800, cursor: !selectedSlotId || bookingBusy ? 'not-allowed' : 'pointer' }}
                >
                  {bookingBusy ? 'Saving...' : 'Confirm Booked'}
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      <div className="card glass" style={{ marginTop: '1.5rem' }}>
        <h4 style={{ margin: '0 0 1rem 0', fontWeight: 900 }}>Booking Control</h4>
        <div style={{ display: 'grid', gap: '0.75rem' }}>
          <div style={{ color: '#cbd5e1', fontWeight: 700, fontSize: '0.85rem' }}>
            Selected Slot: <span style={{ color: '#5eead4' }}>{selectedSlotId || 'None'}</span>
          </div>
          <input
            value={manualStudentEmail}
            onChange={(e) => setManualStudentEmail(e.target.value)}
            placeholder="Student email (optional)"
            className="input-field"
            style={{ width: '100%', padding: '0.75rem', background: '#0f172a', border: '1px solid var(--border)', borderRadius: '0.75rem', color: 'white' }}
          />
          <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
            <button
              onClick={() => createOrUpdateBooking({
                spotId: selectedSlotId,
                status: 'pending',
                studentEmail: manualStudentEmail,
                source: 'staff-request',
              })}
              disabled={!selectedSlotId || bookingBusy}
              style={{ padding: '0.65rem 0.95rem', borderRadius: '0.7rem', border: '1px solid #f59e0b55', background: '#f59e0b22', color: '#fbbf24', fontWeight: 800, cursor: !selectedSlotId || bookingBusy ? 'not-allowed' : 'pointer' }}
            >
              {bookingBusy ? 'Saving...' : 'Create Pending'}
            </button>
            {canManageParkingBookings && (
              <button
                onClick={() => createOrUpdateBooking({
                  spotId: selectedSlotId,
                  status: 'booked',
                  studentEmail: manualStudentEmail,
                  source: 'security-manual',
                })}
                disabled={!selectedSlotId || bookingBusy}
                style={{ padding: '0.65rem 0.95rem', borderRadius: '0.7rem', border: '1px solid #14b8a655', background: '#14b8a622', color: '#2dd4bf', fontWeight: 800, cursor: !selectedSlotId || bookingBusy ? 'not-allowed' : 'pointer' }}
              >
                {bookingBusy ? 'Saving...' : 'Security Manual Book'}
              </button>
            )}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 600 }}>
            Student app bookings show here as pending. Security can confirm to booked, mark exit to completed, and clear after completion.
          </div>
        </div>
      </div>

      <div className="card glass" style={{ marginTop: '1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h4 style={{ margin: 0, fontWeight: 900 }}>
            {isSecurityUser ? 'Student Visible Parking Slots' : 'Student Slot Activity'}
          </h4>
          <span style={{ fontSize: '0.75rem', color: 'var(--muted)', fontWeight: 700 }}>
            LIVE BOOKINGS: {bookingSlots.length}
          </span>
        </div>

        {bookingSlots.length === 0 ? (
          <div style={{ color: 'var(--muted)', fontWeight: 600 }}>No student slot records yet.</div>
        ) : isSecurityUser ? (
          <div style={{ display: 'grid', gap: '1rem' }}>
            <div>
              <div style={{ marginBottom: '0.6rem', fontSize: '0.78rem', fontWeight: 800, color: '#94a3b8', letterSpacing: '0.06em' }}>
                ACTIVE STUDENT SLOTS ({activeStudentSlots.length})
              </div>
              <div style={{ display: 'grid', gap: '0.75rem' }}>
                {activeStudentSlots.length === 0 ? (
                  <div style={{ color: 'var(--muted)', fontWeight: 600 }}>No pending or booked slots right now.</div>
                ) : (
                  activeStudentSlots.map(renderSlotRow)
                )}
              </div>
            </div>

            <div>
              <div style={{ marginBottom: '0.6rem', fontSize: '0.78rem', fontWeight: 800, color: '#94a3b8', letterSpacing: '0.06em' }}>
                COMPLETED SLOTS ({completedStudentSlots.length})
              </div>
              <div style={{ display: 'grid', gap: '0.75rem' }}>
                {completedStudentSlots.length === 0 ? (
                  <div style={{ color: 'var(--muted)', fontWeight: 600 }}>No completed slot records yet.</div>
                ) : (
                  completedStudentSlots.map(renderSlotRow)
                )}
              </div>
            </div>
          </div>
        ) : (
          <div style={{ display: 'grid', gap: '0.75rem' }}>
            {bookingSlots.map(renderSlotRow)}
          </div>
        )}
      </div>
    </div>
  );
}




export default Dashboard;

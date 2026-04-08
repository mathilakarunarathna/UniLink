import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    Lock,
    Mail,
    UtensilsCrossed,
    ArrowRight,
    ChevronRight,
    Eye,
    EyeOff,
    Bus,
    ShieldCheck,
    Car
} from 'lucide-react';
import { sendPasswordResetEmail, signInWithEmailAndPassword } from 'firebase/auth';
import { collection, doc, getDoc, getDocs, limit, query, serverTimestamp, setDoc, where } from 'firebase/firestore';
import { auth, db } from '../firebase';

const normalizeRole = (role) => {
    if (!role) return '';
    const normalized = String(role).trim().toLowerCase().replace(/\s+/g, '_');

    if (normalized === 'cafeteria') return 'cafeteria_manager';
    if (normalized === 'cafe_manager') return 'cafeteria_manager';

    return normalized;
};

const getUserProfile = async (user) => {
    const profileByUid = await getDoc(doc(db, 'users', user.uid));
    if (profileByUid.exists()) {
        return profileByUid.data();
    }

    // Support legacy records where the document id is not the Firebase UID.
    const profileByEmail = await getDocs(
        query(collection(db, 'users'), where('email', '==', user.email), limit(1))
    );

    if (!profileByEmail.empty) {
        return profileByEmail.docs[0].data();
    }

    return null;
};

const roles = [
    { id: 'admin', label: 'Admin', sub: 'Control Center', icon: <ShieldCheck size={22} />, color: '#8b5cf6' },
    { id: 'security', label: 'Security', sub: 'Safety Ops', icon: <Car size={22} />, color: '#14b8a6' },
    { id: 'cafeteria_manager', label: 'Dining', sub: 'Food Ops', icon: <UtensilsCrossed size={22} />, color: '#f59e0b' },
    { id: 'transport_manager', label: 'Shuttle', sub: 'Bus Ops', icon: <Bus size={22} />, color: '#0ea5e9' },
];

function Login({ onLoginSuccess }) {
    const [selectedRole, setSelectedRole] = useState('admin');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [notice, setNotice] = useState('');
    const navigate = useNavigate();

    const handleForgotPassword = async () => {
        const normalizedEmail = email.trim().toLowerCase();
        if (!normalizedEmail) {
            setNotice('');
            setError('Enter your email first, then click Forgot Password.');
            return;
        }

        try {
            setError('');
            await sendPasswordResetEmail(auth, normalizedEmail, {
                url: `${window.location.origin}/login`,
                handleCodeInApp: false,
            });
            setNotice('Password reset link sent. Check your email inbox.');
        } catch (err) {
            setNotice('');
            if (err.code === 'auth/user-not-found') {
                setError('No account found for this email. Ask admin to register this user first.');
            } else if (err.code === 'auth/invalid-email') {
                setError('Invalid email address.');
            } else {
                setError('Could not send reset link right now. Please try again.');
            }
            console.error('Forgot password failed:', err);
        }
    };

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setNotice('');

        try {
            const userCredential = await signInWithEmailAndPassword(auth, email, password);
            const user = userCredential.user;

            const userData = await getUserProfile(user);

            if (userData) {
                const userRole = normalizeRole(userData.role);
                const requestedRole = normalizeRole(selectedRole);
                const isAdminRole = userRole === 'admin';
                const isApprovedByAdmin = userData.approvedByAdmin === true;

                if (userRole !== requestedRole) {
                    setError(`Accreditation required for ${selectedRole.replace('_', ' ')}.`);
                    await auth.signOut();
                } else if (!isAdminRole && !isApprovedByAdmin) {
                    setError('Access pending admin approval. Please contact system administrator.');
                    await auth.signOut();
                } else {
                    // Keep a canonical users/{uid} profile for all approved logins.
                    await setDoc(
                        doc(db, 'users', user.uid),
                        {
                            ...userData,
                            uid: user.uid,
                            email: user.email ?? userData.email ?? '',
                            role: userRole,
                            approvedByAdmin: isAdminRole ? true : isApprovedByAdmin,
                            lastLoginAt: serverTimestamp(),
                        },
                        { merge: true }
                    );

                    const loggedInUser = { ...userData, uid: user.uid, role: userRole };
                    localStorage.setItem('user', JSON.stringify(loggedInUser));
                    if (onLoginSuccess) {
                        onLoginSuccess(loggedInUser);
                    }
                    navigate('/dashboard', { replace: true });
                }
            } else {
                setError('Your staff account is not registered. Ask admin to add you from User Registry.');
                await auth.signOut();
            }
        } catch (err) {
            if (err.code === 'auth/invalid-credential' || err.code === 'auth/wrong-password' || err.code === 'auth/user-not-found') {
                setError('Authorization failed. Please check email and password.');
            } else if (err.code === 'auth/too-many-requests') {
                setError('Too many login attempts. Please wait a moment and try again.');
            } else if (err.code === 'auth/network-request-failed') {
                setError('Network error while authorizing. Please check your connection.');
            } else {
                setError('Authorization failed. Please try again.');
            }
            console.error('Login failed:', err);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{ height: '100vh', display: 'grid', gridTemplateColumns: '1.2fr 1fr', background: '#020617', overflow: 'hidden' }}>

            {/* Left Column: Brand & Visuals */}
            <div style={{ position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', padding: '5rem' }}>
                <div style={{
                    position: 'absolute',
                    inset: 0,
                    backgroundImage: 'url("/login-bg.png")',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    filter: 'brightness(0.5)'
                }} />
                <div style={{
                    position: 'absolute',
                    inset: 0,
                    background: 'linear-gradient(to top, #020617 0%, transparent 80%)'
                }} />

                <div style={{ position: 'relative', zIndex: 1, maxWidth: '600px' }}>
                    <div style={{ width: '40px', height: '4px', background: '#8b5cf6', marginBottom: '2rem' }} />
                    <h1 style={{ fontSize: '4.5rem', fontWeight: 900, letterSpacing: '-0.04em', lineHeight: 1, marginBottom: '2rem' }}>
                        Institutional <br /><span style={{ color: '#14b8a6' }}>Management</span> <br />Terminal.
                    </h1>
                    <p style={{ fontSize: '1.125rem', color: '#94a3b8', lineHeight: 1.6, fontWeight: 500 }}>
                        Unified access system for UniLink campus operations. Securely manage infrastructure, security protocols, and student services from a centralized cloud interface.
                    </p>
                </div>
            </div>

            {/* Right Column: Login Form */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem', background: 'radial-gradient(circle at 70% 30%, #030617, #020617)' }}>
                <div className="glass" style={{
                    width: '100%',
                    maxWidth: '440px',
                    padding: '3.5rem 3rem',
                    borderRadius: '3rem',
                    border: '1px solid rgba(255, 255, 255, 0.08)',
                    boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)'
                }}>
                    <div style={{ marginBottom: '3rem' }}>
                        <h2 style={{ fontSize: '1.75rem', fontWeight: 900, marginBottom: '0.5rem' }}>Sign In</h2>
                        <p style={{ color: '#94a3b8', fontSize: '0.875rem', fontWeight: 600 }}>Enter your institutional credentials</p>
                    </div>

                    {/* Role Selection Horizontal */}
                    <div style={{ display: 'flex', gap: '0.6rem', marginBottom: '2.5rem' }}>
                        {roles.map((role) => (
                            <button
                                key={role.id}
                                type="button"
                                onClick={() => setSelectedRole(role.id)}
                                style={{
                                    flex: 1,
                                    height: '80px',
                                    display: 'flex',
                                    flexDirection: 'column',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    gap: '0.4rem',
                                    background: selectedRole === role.id ? `${role.color}15` : 'rgba(255, 255, 255, 0.03)',
                                    border: `1px solid ${selectedRole === role.id ? role.color : 'rgba(255, 255, 255, 0.08)'}`,
                                    borderRadius: '1.25rem',
                                    cursor: 'pointer',
                                    transition: '0.4s all cubic-bezier(0.4, 0, 0.2, 1)',
                                    color: selectedRole === role.id ? role.color : '#64748b',
                                    boxShadow: selectedRole === role.id ? `0 0 20px ${role.color}15` : 'none'
                                }}
                            >
                                <div style={{
                                    transform: selectedRole === role.id ? 'scale(1.1) translateY(-2px)' : 'scale(1)',
                                    transition: '0.4s transform'
                                }}>
                                    {role.icon}
                                </div>
                                <span style={{
                                    fontSize: '0.65rem',
                                    fontWeight: 900,
                                    letterSpacing: '0.04em',
                                    textTransform: 'uppercase',
                                    opacity: selectedRole === role.id ? 1 : 0.6
                                }}>
                                    {role.label}
                                </span>
                            </button>
                        ))}
                    </div>

                    {error && <div style={{ color: '#f43f5e', background: '#f43f5e1a', padding: '1rem', borderRadius: '1rem', marginBottom: '1rem', fontSize: '0.875rem', textAlign: 'center', fontWeight: 700, border: '1px solid rgba(244, 63, 94, 0.2)' }}>{error}</div>}
                    {notice && <div style={{ color: '#14b8a6', background: 'rgba(20, 184, 166, 0.12)', padding: '1rem', borderRadius: '1rem', marginBottom: '1rem', fontSize: '0.875rem', textAlign: 'center', fontWeight: 700, border: '1px solid rgba(20, 184, 166, 0.3)' }}>{notice}</div>}

                    <form onSubmit={handleLogin} style={{ display: 'grid', gap: '1.25rem' }}>
                        <div>
                            <div style={{
                                position: 'relative',
                                transition: '0.4s cubic-bezier(0.4, 0, 0.2, 1)'
                            }}>
                                <Mail style={{
                                    position: 'absolute',
                                    left: '1.5rem',
                                    top: '50%',
                                    transform: 'translateY(-50%)',
                                    color: email ? roles.find(r => r.id === selectedRole)?.color : '#64748b',
                                    transition: '0.3s color'
                                }} size={20} />
                                <input
                                    type="email"
                                    placeholder="Official Email"
                                    className="input-field"
                                    style={{
                                        paddingLeft: '3.5rem',
                                        border: `1px solid ${email ? roles.find(r => r.id === selectedRole)?.color + '40' : 'rgba(255,255,255,0.1)'}`,
                                        boxShadow: email ? `0 0 20px ${roles.find(r => r.id === selectedRole)?.color}10` : 'none'
                                    }}
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                />
                            </div>
                        </div>

                        <div>
                            <div style={{
                                position: 'relative',
                                transition: '0.4s cubic-bezier(0.4, 0, 0.2, 1)'
                            }}>
                                <Lock style={{
                                    position: 'absolute',
                                    left: '1.5rem',
                                    top: '50%',
                                    transform: 'translateY(-50%)',
                                    color: password ? roles.find(r => r.id === selectedRole)?.color : '#64748b',
                                    transition: '0.3s color'
                                }} size={20} />
                                <input
                                    type={showPassword ? "text" : "password"}
                                    placeholder="Access Key"
                                    className="input-field"
                                    style={{
                                        paddingLeft: '3.5rem',
                                        paddingRight: '3.5rem',
                                        border: `1px solid ${password ? roles.find(r => r.id === selectedRole)?.color + '40' : 'rgba(255,255,255,0.1)'}`,
                                        boxShadow: password ? `0 0 20px ${roles.find(r => r.id === selectedRole)?.color}10` : 'none'
                                    }}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    style={{
                                        position: 'absolute',
                                        right: '1.25rem',
                                        top: '50%',
                                        transform: 'translateY(-50%)',
                                        background: 'transparent',
                                        border: 'none',
                                        color: '#64748b',
                                        cursor: 'pointer',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        padding: '0.5rem',
                                        borderRadius: '0.5rem',
                                        transition: '0.2s all'
                                    }}
                                    onMouseEnter={(e) => e.currentTarget.style.color = '#94a3b8'}
                                    onMouseLeave={(e) => e.currentTarget.style.color = '#64748b'}
                                >
                                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                </button>
                            </div>
                        </div>

                        <button
                            className="btn-primary"
                            style={{
                                background: roles.find(r => r.id === selectedRole)?.color || 'var(--primary)',
                                boxShadow: `0 20px 40px -10px ${roles.find(r => r.id === selectedRole)?.color}4d`,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: '0.75rem'
                            }}
                            disabled={loading}
                        >
                            {loading ? 'Authorizing...' : `Sign In as ${selectedRole.split('_')[0]}`}
                            <ChevronRight size={20} />
                        </button>

                        <button
                            type="button"
                            onClick={handleForgotPassword}
                            style={{
                                marginTop: '0.2rem',
                                background: 'transparent',
                                border: '1px solid rgba(148, 163, 184, 0.35)',
                                color: '#94a3b8',
                                borderRadius: '0.9rem',
                                padding: '0.8rem 1rem',
                                fontWeight: 700,
                                cursor: 'pointer'
                            }}
                        >
                            Forgot Password
                        </button>
                    </form>

                    <div style={{ marginTop: '3.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', opacity: 0.5 }}>
                        <span style={{ fontSize: '0.75rem', fontWeight: 700 }}>VER 2.5.0</span>
                        <span style={{ fontSize: '0.75rem', fontWeight: 700 }}>UNILINK SYSTEMS</span>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default Login;

import { useState, useEffect } from 'react';
import { 
  Utensils, 
  Clock, 
  Plus, 
  Pencil, 
  Trash2, 
  Settings, 
  CheckCircle2, 
  XCircle,
  AlertCircle,
  Search,
  Filter,
  DollarSign,
  Store,
  ChevronRight,
  TrendingUp,
  Wallet
} from 'lucide-react';
import { db } from '../firebase';
import { 
  collection, 
  getDocs, 
  addDoc, 
  updateDoc, 
  deleteDoc,
  doc, 
  onSnapshot, 
  query, 
  orderBy,
  Timestamp,
  serverTimestamp,
  where,
  increment,
} from 'firebase/firestore';

function CafeteriaManager() {
  const [activeTab, setActiveTab] = useState('orders'); // orders, menu, settings
  const [orders, setOrders] = useState([]);
  const [menuItems, setMenuItems] = useState([]);
  const [shopInfo, setShopInfo] = useState(null);
  const [allShops, setAllShops] = useState([]); // For Admins to choose from
  const [loading, setLoading] = useState(true);
  const [selectedPrepTime, setSelectedPrepTime] = useState({}); // orderId -> minutes
  
  // Form states for adding/editing menu items
  const [isMenuModalOpen, setIsMenuModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);
  const [menuForm, setMenuForm] = useState({
    name: '',
    description: '',
    price: '',
    category: 'General',
    status: 'Available',
    preparationMinutes: 15,
    image: ''
  });

  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const userEmail = user?.email?.toLowerCase();

  // 1. Fetch Shop Info based on user email OR load all shops for Admin
  useEffect(() => {
    const fetchInitialData = async () => {
      if (user.role === 'admin') {
        const shopsSnap = await getDocs(collection(db, 'cafeteria_shops'));
        const shopsList = shopsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
        setAllShops(shopsList);
        if (shopsList.length > 0) setShopInfo(shopsList[0]);
      } else if (userEmail) {
        const q = query(
          collection(db, 'cafeteria_shops'), 
          where('shopEmail', '==', userEmail)
        );
        const snapshot = await getDocs(q);
        if (!snapshot.empty) {
          setShopInfo({ id: snapshot.docs[0].id, ...snapshot.docs[0].data() });
        }
      }
    };
    fetchInitialData();
  }, [userEmail, user.role]);

  // 2. Real-time Orders Listener (Scoped to Shop if shopInfo exists)
  useEffect(() => {
    if (!shopInfo?.id && user.role !== 'admin') return;

    let q;
    if (user.role === 'admin') {
      q = query(
        collection(db, 'orders'), 
        where('type', '==', 'Food'),
        orderBy('createdAt', 'desc')
      );
    } else {
      q = query(
        collection(db, 'orders'), 
        where('type', '==', 'Food'),
        where('shopId', '==', shopInfo.id),
        orderBy('createdAt', 'desc')
      );
    }
    
    const unsub = onSnapshot(q, (snapshot) => {
      const ordersList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setOrders(ordersList);
      setLoading(false);
    }, (error) => {
      console.error("Firestore error:", error);
      setLoading(false);
    });
    return () => unsub();
  }, [shopInfo?.id, user.role]);

  // 3. Menu Items Listener (Scoped to selected Shop)
  useEffect(() => {
    if (!shopInfo?.id) return;

    const q = query(
      collection(db, 'cafeteria_menu'), 
      where('shopId', '==', shopInfo.id),
      orderBy('name', 'asc')
    );

    const unsub = onSnapshot(q, (snapshot) => {
      const menuList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setMenuItems(menuList);
    });
    return () => unsub();
  }, [shopInfo?.id]);

  const updateOrderStatus = async (orderId, status, prepMinutes = null) => {
    try {
      const orderRef = doc(db, 'orders', orderId);
      const updates = { status, updatedAt: serverTimestamp() };
      
      if (prepMinutes) {
        const readyAt = new Date();
        readyAt.setMinutes(readyAt.getMinutes() + Number(prepMinutes));
        updates.estimatedReadyAt = Timestamp.fromDate(readyAt);
        updates.prepTimeMinutes = Number(prepMinutes);
      }

      await updateDoc(orderRef, updates);
      
      if (status === 'Completed') {
        const orderData = orders.find(o => o.id === orderId);
        if (orderData && orderData.shopId && orderData.totalAmount) {
          const shopRef = doc(db, 'cafeteria_shops', orderData.shopId);
          await updateDoc(shopRef, {
            balance: increment(Number(orderData.totalAmount)),
            updatedAt: serverTimestamp()
          });
        }
      }
      
      const newPrepTimes = { ...selectedPrepTime };
      delete newPrepTimes[orderId];
      setSelectedPrepTime(newPrepTimes);
    } catch (error) {
      alert("Failed to update order status: " + error.message);
    }
  };

  const handleSaveMenuItem = async (e) => {
    e.preventDefault();
    if (!shopInfo?.id) return alert("Shop info not found. Cannot save menu.");

    const payload = {
      ...menuForm,
      price: Number(menuForm.price),
      preparationMinutes: Number(menuForm.preparationMinutes),
      shopId: shopInfo.id,
      shopName: shopInfo.shopName,
      updatedAt: serverTimestamp()
    };

    try {
      if (editingItem) {
        await updateDoc(doc(db, 'cafeteria_menu', editingItem.id), payload);
      } else {
        await addDoc(collection(db, 'cafeteria_menu'), {
          ...payload,
          createdAt: serverTimestamp()
        });
      }
      setIsMenuModalOpen(false);
      setEditingItem(null);
      setMenuForm({ name: '', description: '', price: '', category: 'General', status: 'Available', preparationMinutes: 15, image: '' });
    } catch (err) {
      alert("Error saving item: " + err.message);
    }
  };

  const handleDeleteMenuItem = async (id) => {
    if (window.confirm("Are you sure you want to delete this item?")) {
      await deleteDoc(doc(db, 'cafeteria_menu', id));
    }
  };

  const handleDeleteShop = async () => {
    if (!shopInfo?.id) return;
    
    const confirmName = window.prompt(`To delete ${shopInfo.shopName} and ALL its data, please type the shop name to confirm:`);
    if (confirmName !== shopInfo.shopName) return alert("Confirmation name did not match. Deletion cancelled.");

    if (!window.confirm("FINAL WARNING: This will permanently delete the shop account and all menu items. This cannot be undone. Are you absolutely sure?")) return;

    try {
      // 1. Delete all menu items
      const menuSnap = await getDocs(query(collection(db, 'cafeteria_menu'), where('shopId', '==', shopInfo.id)));
      const deletePromises = menuSnap.docs.map(d => deleteDoc(doc(db, 'cafeteria_menu', d.id)));
      await Promise.all(deletePromises);

      // 2. Delete the shop document
      await deleteDoc(doc(db, 'cafeteria_shops', shopInfo.id));

      alert("Shop and all menu items successfully deleted.");
      
      // 3. Post-deletion state handling
      if (user.role === 'admin') {
        const remainingShops = allShops.filter(s => s.id !== shopInfo.id);
        setAllShops(remainingShops);
        setShopInfo(remainingShops.length > 0 ? remainingShops[0] : null);
      } else {
        setShopInfo(null); // Manager is now orphaned
      }
    } catch (err) {
      alert("Error deleting shop: " + err.message);
    }
  };

  const formatPrice = (amount, currency = 'LKR') => {
    return `${currency} ${Number(amount || 0).toLocaleString()}`;
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'Pending': return '#f59e0b';
      case 'Preparing': return '#3b82f6';
      case 'Ready': return '#10b981';
      case 'Completed': return '#94a3b8';
      case 'Cancelled': return '#ef4444';
      default: return '#94a3b8';
    }
  };

  if (loading && orders.length === 0) {
    return <div style={{ padding: '4rem', textAlign: 'center', color: 'var(--muted)', minHeight: '80vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>Initializing Manager...</div>;
  }

  if (!shopInfo && user.role !== 'admin') {
    return (
      <div style={{ maxWidth: '600px', margin: '4rem auto', textAlign: 'center' }} className="card glass">
        <div style={{ background: 'rgba(239, 68, 68, 0.1)', width: '80px', height: '80px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1.5rem' }}>
          <Store size={40} color="#ef4444" />
        </div>
        <h2 style={{ fontSize: '1.75rem', fontWeight: 900 }}>Branch Not Found</h2>
        <p style={{ color: 'var(--muted)', marginTop: '1rem' }}>It seems your branch has been deleted or is not yet configured. Please contact the system administrator to register your cafeteria.</p>
        <button 
          onClick={() => window.location.reload()}
          style={{ marginTop: '2rem', padding: '0.75rem 1.5rem', borderRadius: '0.85rem', background: 'var(--primary)', color: 'white', fontWeight: 900, border: 'none', cursor: 'pointer' }}
        >
          Check Again
        </button>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      {/* Header & Stats Summary */}
      <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <div>
          <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary)', letterSpacing: '0.15em', marginBottom: '0.5rem', textTransform: 'uppercase' }}>
            {shopInfo?.shopName || 'Branch Manager'} Admin
          </div>
          <h2 style={{ fontSize: '2.5rem', fontWeight: 900, letterSpacing: '-0.03em' }}>Digital Operations</h2>
          <p style={{ color: 'var(--muted)', marginTop: '0.25rem' }}>Manage your branch menu, kitchen queue, and business settings.</p>
        </div>
        
        <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-end' }}>
           {user.role === 'admin' && (
             <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <label style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted)' }}>SWITCH BRANCH</label>
                <select 
                  className="card glass" 
                  style={{ padding: '0.5rem 1rem', borderRadius: '0.75rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white', fontWeight: 800, cursor: 'pointer' }}
                  onChange={(e) => {
                    const shop = allShops.find(s => s.id === e.target.value);
                    if (shop) setShopInfo(shop);
                  }}
                  value={shopInfo?.id || ''}
                >
                  {allShops.map(s => (
                    <option key={s.id} value={s.id}>{s.shopName}</option>
                  ))}
                </select>
             </div>
           )}
           <div className="card glass" style={{ padding: '0.75rem 1.25rem', display: 'flex', alignItems: 'center', gap: '0.75rem', border: '1px solid var(--border)' }}>
              <div style={{ background: 'rgba(16, 185, 129, 0.1)', padding: '0.5rem', borderRadius: '0.75rem' }}>
                <Wallet size={18} color="#10b981" />
              </div>
              <div>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted)', letterSpacing: '0.05em' }}>BALANCE</div>
                <div style={{ fontWeight: 900, fontSize: '1rem' }}>{formatPrice(shopInfo?.balance || 0)}</div>
              </div>
           </div>
        </div>
      </header>

      {/* Navigation Tabs */}
      <div style={{ 
        display: 'flex', 
        gap: '0.5rem', 
        marginBottom: '2rem', 
        background: 'rgba(255,255,255,0.03)', 
        padding: '0.4rem', 
        borderRadius: '1rem',
        width: 'fit-content',
        border: '1px solid var(--border)'
      }}>
        {[
          { id: 'orders', label: 'Kitchen Queue', icon: <Utensils size={18} /> },
          { id: 'menu', label: 'Menu Editor', icon: <Plus size={18} /> },
          { id: 'settings', label: 'Shop Settings', icon: <Settings size={18} /> }
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.6rem',
              padding: '0.6rem 1.25rem',
              borderRadius: '0.75rem',
              border: 'none',
              background: activeTab === tab.id ? 'var(--primary)' : 'transparent',
              color: activeTab === tab.id ? 'white' : 'var(--muted)',
              fontSize: '0.85rem',
              fontWeight: 800,
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content Rendering based on Active Tab */}
      
      {activeTab === 'orders' && (
        <div style={{ display: 'grid', gap: '1.25rem' }}>
          {orders.map(order => {
            const statusTone = getStatusColor(order.status);
            const isPreparing = order.status === 'Preparing';
            const isPending = order.status === 'Pending';
            const isReady = order.status === 'Ready';
            
            return (
              <div 
                key={order.id} 
                className="card glass" 
                style={{ 
                  display: 'flex', 
                  flexDirection: 'column',
                  gap: '1.5rem', 
                  border: `1px solid ${statusTone}44`,
                  padding: '1.5rem',
                  position: 'relative',
                  overflow: 'hidden'
                }}
              >
                {/* Visual indicator for status */}
                <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '4px', background: statusTone }}></div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
                    <div style={{ 
                      background: 'rgba(255,255,255,0.03)', 
                      padding: '1rem', 
                      borderRadius: '1.25rem', 
                      textAlign: 'center', 
                      minWidth: '100px',
                      border: '1px solid var(--border)'
                    }}>
                      <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted)', marginBottom: '0.2rem' }}>ORD-#{order.orderNumber?.split('-').pop() || '000'}</div>
                      <div style={{ fontWeight: 900, fontSize: '1.1rem', color: statusTone }}>{order.status.toUpperCase()}</div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--muted)', marginBottom: '0.4rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <Clock size={14} /> {new Date(order.createdAt?.seconds * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} • {order.studentEmail}
                      </div>
                      <div style={{ display: 'flex', gap: '0.6rem', flexWrap: 'wrap' }}>
                        {order.items?.map((item, idx) => (
                          <span key={idx} style={{ 
                            fontSize: '0.85rem', 
                            fontWeight: 800, 
                            background: 'rgba(255,255,255,0.05)', 
                            padding: '0.4rem 0.8rem', 
                            borderRadius: '0.75rem',
                            border: '1px solid var(--border)',
                            color: 'white'
                          }}>
                            {item.quantity}x {item.itemName}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '1.5rem', fontWeight: 900 }}>{formatPrice(order.totalAmount, order.currency)}</div>
                    <div style={{ fontSize: '0.75rem', fontWeight: 800, color: '#10b981', background: 'rgba(16,185,129,0.1)', padding: '0.2rem 0.6rem', borderRadius: '0.5rem', display: 'inline-block', marginTop: '0.4rem' }}>
                      PAID • {order.paymentMethod || 'Wallet'}
                    </div>
                  </div>
                </div>

                <div style={{ 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center', 
                  paddingTop: '1.25rem', 
                  borderTop: '1px solid var(--border)',
                  gap: '1rem'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    {isPending && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                        <span style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--muted)', marginRight: '0.5rem' }}>Set Preparation:</span>
                        {[5, 10, 15, 20, 30].map(m => (
                          <button 
                            key={m}
                            onClick={() => setSelectedPrepTime({...selectedPrepTime, [order.id]: m})}
                            style={{ 
                              padding: '0.5rem 0.85rem', 
                              borderRadius: '0.75rem', 
                              background: selectedPrepTime[order.id] === m ? 'var(--primary)' : 'rgba(255,255,255,0.05)',
                              border: '1px solid var(--border)',
                              color: 'white',
                              fontSize: '0.8rem',
                              fontWeight: 900,
                              cursor: 'pointer',
                              transition: 'all 0.2s'
                            }}
                          >
                            {m}m
                          </button>
                        ))}
                        <button 
                          disabled={!selectedPrepTime[order.id]}
                          onClick={() => updateOrderStatus(order.id, 'Preparing', selectedPrepTime[order.id])} 
                          style={{ 
                            padding: '0.75rem 1.5rem', 
                            borderRadius: '0.85rem', 
                            background: 'var(--primary)', 
                            border: 'none', 
                            color: 'white', 
                            fontWeight: 900, 
                            cursor: !selectedPrepTime[order.id] ? 'not-allowed' : 'pointer',
                            opacity: !selectedPrepTime[order.id] ? 0.5 : 1,
                            marginLeft: '1rem',
                            boxShadow: selectedPrepTime[order.id] ? '0 4px 12px var(--primary-glow)' : 'none'
                          }}
                        >
                          START PREPARING
                        </button>
                      </div>
                    )}

                    {isPreparing && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
                        <div style={{ color: '#3b82f6', fontWeight: 900, fontSize: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#3b82f6', animation: 'pulse 1.5s infinite opacity' }}></div>
                          Preparing (Ready in ~{order.prepTimeMinutes}m)
                        </div>
                        <button 
                          onClick={() => updateOrderStatus(order.id, 'Ready')} 
                          style={{ 
                            padding: '0.75rem 1.5rem', 
                            borderRadius: '0.85rem', 
                            background: '#10b981', 
                            border: 'none', 
                            color: 'white', 
                            fontWeight: 900, 
                            cursor: 'pointer',
                            boxShadow: '0 4px 12px rgba(16, 185, 129, 0.3)'
                          }}
                        >
                          MARK AS READY
                        </button>
                      </div>
                    )}

                    {isReady && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
                        <div style={{ color: '#10b981', fontWeight: 900, fontSize: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                           <CheckCircle2 size={20} /> Ready for Pickup
                        </div>
                        <button 
                          onClick={() => updateOrderStatus(order.id, 'Completed')} 
                          style={{ 
                            padding: '0.75rem 1.5rem', 
                            borderRadius: '0.85rem', 
                            background: 'rgba(255,255,255,0.05)', 
                            border: '1px solid #10b981', 
                            color: 'white', 
                            fontWeight: 900, 
                            cursor: 'pointer'
                          }}
                        >
                          COMPLETE PICKUP
                        </button>
                      </div>
                    )}

                    {order.status === 'Completed' && (
                      <div style={{ color: 'var(--muted)', fontWeight: 800, fontSize: '0.9rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <CheckCircle2 size={18} /> Order fulfilled successfully
                      </div>
                    )}
                  </div>

                  {order.status !== 'Completed' && order.status !== 'Cancelled' && (
                    <button 
                      onClick={() => { if(window.confirm("Cancel this order?")) updateOrderStatus(order.id, 'Cancelled'); }}
                      style={{ background: 'transparent', border: 'none', color: '#ef4444', fontSize: '0.8rem', fontWeight: 800, cursor: 'pointer' }}
                    >
                      Cancel Order
                    </button>
                  )}
                </div>
              </div>
            );
          })}
          {orders.length === 0 && (
            <div className="card glass" style={{ textAlign: 'center', padding: '6rem 2rem', color: 'var(--muted)', border: '1px dashed var(--border)' }}>
              <div style={{ background: 'rgba(255,255,255,0.03)', width: '80px', height: '80px', borderRadius: '2rem', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 1.5rem' }}>
                <TrendingUp size={40} style={{ opacity: 0.2 }} />
              </div>
              <div style={{ fontSize: '1.5rem', fontWeight: 900, color: 'white', marginBottom: '0.5rem' }}>Kitchen is All Clear</div>
              <div>No active orders are waiting in the queue. New orders will appear here automatically.</div>
            </div>
          )}
        </div>
      )}

      {activeTab === 'menu' && (
        <div style={{ display: 'grid', gap: '2rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 900 }}>Branch Menu Inventory</h3>
            <button 
              onClick={() => { setEditingItem(null); setMenuForm({ name: '', description: '', price: '', category: 'General', status: 'Available', preparationMinutes: 15, image: '' }); setIsMenuModalOpen(true); }}
              style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1.25rem', borderRadius: '0.85rem', background: 'var(--primary)', color: 'white', fontWeight: 900, border: 'none', cursor: 'pointer' }}
            >
              <Plus size={18} /> Add New Item
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.25rem' }}>
            {menuItems.map(item => (
              <div key={item.id} className="card glass" style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1rem', border: '1px solid var(--border)' }}>
                <div style={{ display: 'flex', gap: '1rem' }}>
                  <div style={{ 
                    width: '80px', 
                    height: '80px', 
                    borderRadius: '1rem', 
                    background: 'rgba(255,255,255,0.05)', 
                    overflow: 'hidden',
                    flexShrink: 0
                  }}>
                    {item.image ? (
                      <img src={item.image} alt={item.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    ) : (
                      <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted)' }}>
                        <Utensils size={24} />
                      </div>
                    )}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <span style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--primary)', letterSpacing: '0.05em' }}>{item.category.toUpperCase()}</span>
                      <span style={{ 
                        fontSize: '0.65rem', 
                        fontWeight: 900, 
                        color: item.status === 'Available' ? '#10b981' : '#ef4444', 
                        background: item.status === 'Available' ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)', 
                        padding: '0.2rem 0.5rem', 
                        borderRadius: '0.4rem' 
                      }}>
                        {item.status.toUpperCase()}
                      </span>
                    </div>
                    <div style={{ fontWeight: 900, fontSize: '1.1rem', margin: '0.2rem 0' }}>{item.name}</div>
                    <div style={{ fontSize: '1.2rem', fontWeight: 900, color: 'white' }}>{formatPrice(item.price)}</div>
                  </div>
                </div>
                
                <p style={{ fontSize: '0.85rem', color: 'var(--muted)', margin: 0, lineClamp: 2, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                  {item.description}
                </p>

                <div style={{ display: 'flex', gap: '0.75rem', marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid var(--border)' }}>
                  <button 
                    onClick={() => { setEditingItem(item); setMenuForm({...item}); setIsMenuModalOpen(true); }}
                    style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', padding: '0.6rem', borderRadius: '0.6rem', background: 'rgba(255,255,255,0.05)', color: 'white', fontWeight: 800, border: '1px solid var(--border)', cursor: 'pointer' }}
                  >
                    <Pencil size={14} /> Edit
                  </button>
                  <button 
                    onClick={() => handleDeleteMenuItem(item.id)}
                    style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', padding: '0.6rem', borderRadius: '0.6rem', background: 'rgba(239,68,68,0.05)', color: '#ef4444', fontWeight: 800, border: '1px solid rgba(239,68,68,0.1)', cursor: 'pointer' }}
                  >
                    <Trash2 size={14} /> Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'settings' && (
        <div style={{ display: 'grid', gap: '2rem', maxWidth: '700px' }}>
          <h3 style={{ fontSize: '1.5rem', fontWeight: 900 }}>Branch Settings</h3>
          
          <div className="card glass" style={{ padding: '2rem', display: 'grid', gap: '1.5rem', border: '1px solid var(--border)' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.5rem', letterSpacing: '0.05em' }}>BRANCH NAME</label>
              <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.03)', borderRadius: '1rem', border: '1px solid var(--border)', fontWeight: 800 }}>
                {shopInfo?.shopName}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.5rem', letterSpacing: '0.05em' }}>CONTACT EMAIL</label>
              <div style={{ padding: '1rem', background: 'rgba(255,255,255,0.03)', borderRadius: '1rem', border: '1px solid var(--border)', fontWeight: 800 }}>
                {shopInfo?.shopEmail}
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.5rem', letterSpacing: '0.05em' }}>BRANCH CATEGORY</label>
              <select 
                defaultValue={shopInfo?.category || 'Fast Food'}
                onChange={async (e) => {
                  if (shopInfo?.id) await updateDoc(doc(db, 'cafeteria_shops', shopInfo.id), { category: e.target.value });
                }}
                className="glass-input"
                style={{ width: '100%', padding: '1rem', borderRadius: '1rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white', fontWeight: 800, cursor: 'pointer' }}
              >
                <option value="Fast Food">Fast Food</option>
                <option value="Coffee">Coffee</option>
                <option value="Healthy">Healthy</option>
                <option value="Snacks">Snacks</option>
                <option value="Dessert">Dessert</option>
              </select>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.5rem', letterSpacing: '0.05em' }}>SHOP LOGO / IMAGE URL</label>
              <input 
                type="text" 
                defaultValue={shopInfo?.image || ''}
                placeholder="https://example.com/logo.png"
                onBlur={async (e) => {
                  if (shopInfo?.id) await updateDoc(doc(db, 'cafeteria_shops', shopInfo.id), { image: e.target.value });
                }}
                className="glass-input"
                style={{ width: '100%', padding: '1rem', borderRadius: '1rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white', fontWeight: 800 }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.5rem', letterSpacing: '0.05em' }}>OPENING HOURS</label>
              <input 
                type="text" 
                defaultValue={shopInfo?.openingHours || '08:00 AM - 08:00 PM'}
                placeholder="e.g. 08:00 AM - 09:00 PM"
                onBlur={async (e) => {
                  if (shopInfo?.id) await updateDoc(doc(db, 'cafeteria_shops', shopInfo.id), { openingHours: e.target.value });
                }}
                className="glass-input"
                style={{ width: '100%', padding: '1rem', borderRadius: '1rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white', fontWeight: 800 }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.5rem', letterSpacing: '0.05em' }}>SHOP DESCRIPTION</label>
              <textarea 
                defaultValue={shopInfo?.description || 'Authentic campus meals and favorites.'}
                placeholder="Briefly describe your cafe..."
                onBlur={async (e) => {
                  if (shopInfo?.id) await updateDoc(doc(db, 'cafeteria_shops', shopInfo.id), { description: e.target.value });
                }}
                rows={3}
                className="glass-input"
                style={{ width: '100%', padding: '1rem', borderRadius: '1rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white', fontWeight: 800, resize: 'none' }}
              />
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginTop: '1rem' }}>
              <div style={{ 
                width: '12px', 
                height: '12px', 
                borderRadius: '50%', 
                background: shopInfo?.isActive ? '#10b981' : '#ef4444' 
              }}></div>
              <div style={{ fontWeight: 800 }}>Branch is currently {shopInfo?.isActive ? 'Online & Visible' : 'Offline'}</div>
              <button 
                onClick={async () => {
                  if (shopInfo?.id) await updateDoc(doc(db, 'cafeteria_shops', shopInfo.id), { isActive: !shopInfo.isActive });
                  setShopInfo({...shopInfo, isActive: !shopInfo.isActive});
                }}
                style={{ marginLeft: 'auto', padding: '0.5rem 1rem', borderRadius: '0.6rem', background: 'rgba(255,255,255,0.05)', color: 'white', fontWeight: 800, border: '1px solid var(--border)', cursor: 'pointer' }}
              >
                Toggle Status
              </button>
            </div>
          </div>

          <div className="card glass" style={{ padding: '2rem', border: '1px solid var(--border)' }}>
             <h4 style={{ fontSize: '1.1rem', fontWeight: 900, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <TrendingUp size={20} color="var(--primary)" />
                Recent Sales & Earnings
             </h4>
             <div style={{ display: 'grid', gap: '1rem' }}>
                {orders.filter(o => o.status === 'Completed').slice(0, 10).map(o => (
                  <div key={o.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', borderRadius: '0.75rem', background: 'rgba(255,255,255,0.02)', border: '1px solid var(--border)' }}>
                    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                      <div style={{ background: 'rgba(16,185,129,0.1)', width: '32px', height: '32px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <DollarSign size={16} color="#10b981" />
                      </div>
                      <div>
                        <div style={{ fontWeight: 800, fontSize: '0.9rem' }}>{o.items?.[0]?.itemName || 'Anonymous Order'} {o.items?.length > 1 ? `(+${o.items.length-1} more)` : ''}</div>
                        <div style={{ fontSize: '0.7rem', color: 'var(--muted)', fontWeight: 700 }}>{new Date(o.createdAt?.seconds * 1000).toLocaleDateString()} at {new Date(o.createdAt?.seconds * 1000).toLocaleTimeString()}</div>
                      </div>
                    </div>
                    <div style={{ fontWeight: 900, color: '#10b981' }}>
                      + {formatPrice(o.totalAmount, o.currency)}
                    </div>
                  </div>
                ))}
                {orders.filter(o => o.status === 'Completed').length === 0 && (
                  <div style={{ textAlign: 'center', color: 'var(--muted)', padding: '2rem' }}>No completed sales yet.</div>
                )}
             </div>
          </div>

          <div className="card glass" style={{ padding: '2rem', marginTop: '2rem', border: '1px solid rgba(239, 68, 68, 0.2)', background: 'linear-gradient(to bottom, rgba(239, 68, 68, 0.05), transparent)' }}>
             <h4 style={{ fontSize: '1.1rem', fontWeight: 900, marginBottom: '1rem', color: '#ef4444', display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                <AlertCircle size={20} /> Danger Zone
             </h4>
             <p style={{ fontSize: '0.85rem', color: 'var(--muted)', marginBottom: '1.5rem', fontWeight: 700 }}>
                Permanently remove this branch and all its menu inventory from UniLink. This action is irreversible once confirmed.
             </p>
             <button 
               onClick={handleDeleteShop}
               style={{ 
                 width: '100%', 
                 padding: '1rem', 
                 borderRadius: '1rem', 
                 background: '#ef4444', 
                 color: 'white', 
                 fontSize: '0.9rem', 
                 fontWeight: 900, 
                 border: 'none', 
                 cursor: 'pointer',
                 boxShadow: '0 4px 12px rgba(239, 68, 68, 0.3)'
               }}
             >
               DELETE BRANCH PERMANENTLY
             </button>
          </div>
        </div>
      )}

      {/* Menu Item Modal */}
      {isMenuModalOpen && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, backdropFilter: 'blur(10px)' }}>
          <div className="card glass" style={{ width: '100%', maxWidth: '500px', padding: '2rem', border: '1px solid var(--border)' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 900, marginBottom: '1.5rem' }}>{editingItem ? 'Edit Menu Item' : 'Add Menu Item'}</h3>
            <form onSubmit={handleSaveMenuItem} style={{ display: 'grid', gap: '1.25rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.4rem' }}>ITEM NAME</label>
                <input required type="text" value={menuForm.name} onChange={e => setMenuForm({...menuForm, name: e.target.value})} className="glass-input" style={{ width: '100%', padding: '0.85rem', borderRadius: '0.85rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white' }} />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.4rem' }}>PRICE (LKR)</label>
                  <input required type="number" value={menuForm.price} onChange={e => setMenuForm({...menuForm, price: e.target.value})} className="glass-input" style={{ width: '100%', padding: '0.85rem', borderRadius: '0.85rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.4rem' }}>CATEGORY</label>
                  <select value={menuForm.category} onChange={e => setMenuForm({...menuForm, category: e.target.value})} className="glass-input" style={{ width: '100%', padding: '0.85rem', borderRadius: '0.85rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white' }}>
                    <option value="General">General</option>
                    <option value="Meals">Meals</option>
                    <option value="Snacks">Snacks</option>
                    <option value="Drinks">Drinks</option>
                    <option value="Desserts">Desserts</option>
                  </select>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.4rem' }}>STATUS</label>
                <select value={menuForm.status} onChange={e => setMenuForm({...menuForm, status: e.target.value})} className="glass-input" style={{ width: '100%', padding: '0.85rem', borderRadius: '0.85rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white' }}>
                  <option value="Available">Available</option>
                  <option value="Out of Stock">Out of Stock</option>
                </select>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 900, color: 'var(--muted)', marginBottom: '0.4rem' }}>DESCRIPTION</label>
                <textarea rows={2} value={menuForm.description} onChange={e => setMenuForm({...menuForm, description: e.target.value})} className="glass-input" style={{ width: '100%', padding: '0.85rem', borderRadius: '0.85rem', border: '1px solid var(--border)', background: 'rgba(255,255,255,0.03)', color: 'white', resize: 'none' }} />
              </div>

              <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                <button type="button" onClick={() => setIsMenuModalOpen(false)} style={{ flex: 1, padding: '1rem', borderRadius: '1rem', border: '1px solid var(--border)', background: 'transparent', color: 'white', fontWeight: 900, cursor: 'pointer' }}>Cancel</button>
                <button type="submit" style={{ flex: 1, padding: '1rem', borderRadius: '1rem', border: 'none', background: 'var(--primary)', color: 'white', fontWeight: 900, cursor: 'pointer' }}>Save Item</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Global CSS for Animations */}
      <style>{`
        @keyframes pulse {
          0% { transform: scale(0.95); opacity: 0.5; }
          50% { transform: scale(1.05); opacity: 1; }
          100% { transform: scale(0.95); opacity: 0.5; }
        }
        .glass-input:focus {
          outline: none;
          border-color: var(--primary) !important;
          box-shadow: 0 0 0 2px var(--primary-glow);
        }
      `}</style>
    </div>
  );
}

export default CafeteriaManager;

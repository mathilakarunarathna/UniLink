import { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import SeedingTool from './pages/SeedingTool';
import { auth } from './firebase';

const getStoredUser = () => {
  try {
    const raw = localStorage.getItem('user');
    if (!raw) return null;

    const parsed = JSON.parse(raw);
    return parsed && parsed.uid ? parsed : null;
  } catch {
    return null;
  }
};

function App() {
  const [user, setUser] = useState(getStoredUser);
  const isAuthenticated = Boolean(user);

  useEffect(() => {
    const syncUserFromStorage = () => {
      setUser(getStoredUser());
    };

    const unsubscribe = auth.onAuthStateChanged((firebaseUser) => {
      if (!firebaseUser) {
        localStorage.removeItem('user');
        setUser(null);
        return;
      }

      syncUserFromStorage();
    });

    window.addEventListener('storage', syncUserFromStorage);
    window.addEventListener('focus', syncUserFromStorage);

    return () => {
      unsubscribe();
      window.removeEventListener('storage', syncUserFromStorage);
      window.removeEventListener('focus', syncUserFromStorage);
    };
  }, []);

  return (
    <Router>
      <Routes>
        <Route
          path="/login"
          element={
            isAuthenticated ? (
              <Navigate to="/dashboard" replace />
            ) : (
              <Login onLoginSuccess={(loggedInUser) => setUser(loggedInUser)} />
            )
          }
        />
        <Route 
          path="/dashboard/*" 
          element={isAuthenticated ? <Dashboard /> : <Navigate to="/login" replace />} 
        />
        <Route path="/seed" element={<SeedingTool />} />
        <Route path="*" element={<Navigate to={isAuthenticated ? '/dashboard' : '/login'} replace />} />
      </Routes>
    </Router>
  );
}

export default App;

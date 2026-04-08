import { initializeApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, setDoc, collection, serverTimestamp } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyC5vkyaF73lJRLLDnrolzDpFHhAWaILGEA',
  authDomain: 'unilink-97ccb.firebaseapp.com',
  projectId: 'unilink-97ccb',
  storageBucket: 'unilink-97ccb.firebasestorage.app',
  messagingSenderId: '382670272012',
  appId: '1:382670272012:web:4be228364135c737f32029'
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const seedUsers = async () => {
  const users = [
    { email: 'admin@unilink.com', password: 'admin123', name: 'Super Admin', role: 'admin' },
    { email: 'security@unilink.com', password: 'secpassword', name: 'Chief Security', role: 'security' },
    { email: 'cafe@unilink.com', password: 'cafepassword', name: 'Cafeteria Manager', role: 'cafeteria_manager' },
    { email: 'student@unilink.com', password: 'stupassword', name: 'Imansha', role: 'student' }
  ];

  console.log("🚀 Starting Firebase Seeding...");

  for (const user of users) {
    try {
      let uid;
      try {
        // 1. Try to create the user
        const userCredential = await createUserWithEmailAndPassword(auth, user.email, user.password);
        uid = userCredential.user.uid;
        console.log(`✅ Success: Created NEW Auth for ${user.role} (${user.email})`);
      } catch (authError) {
        if (authError.code === 'auth/email-already-in-use') {
          // 2. If user already exists, sign in to get their UID
          const userCredential = await signInWithEmailAndPassword(auth, user.email, user.password);
          uid = userCredential.user.uid;
          console.log(`⚠️ Info: Fetched UID for existing user: ${user.email}`);
        } else {
          throw authError;
        }
      }

      // 3. Always create/update Profile in Firestore
      if (uid) {
        await setDoc(doc(db, 'users', uid), {
          uid: uid,
          name: user.name,
          email: user.email,
          role: user.role,
          createdAt: serverTimestamp()
        }, { merge: true }); // Using merge: true to avoid overwriting existing non-seed data if any
        console.log(`✅ Success: Seeded/Updated Firestore Profile for ${user.role}`);
      }
    } catch (error) {
      console.error(`❌ Error processing ${user.email}:`, error.message);
    }
  }

  // 3. Create Initial Dashboard Data if missing
  try {
    await setDoc(doc(db, 'parking', 'slot_a1'), { zone: 'A', status: 'available', availableSlots: 10, createdAt: serverTimestamp() });
    await setDoc(doc(db, 'parking', 'slot_b1'), { zone: 'B', status: 'full', availableSlots: 0, createdAt: serverTimestamp() });
    console.log("✅ Initial Parking slots created.");
    
    await setDoc(doc(db, 'news', 'welcome_news'), { 
      title: 'Welcome to UniLink', 
      subtitle: 'The best campus companion app is now live!', 
      imageUrl: 'https://images.unsplash.com/photo-1541339907198-e08756ebafe1',
      date: new Date().toLocaleDateString(),
      createdAt: serverTimestamp() 
    });
    console.log("✅ Initial News created.");
  } catch (e) {
    console.error("❌ Error seeding initial data:", e.message);
  }

  console.log("🏁 Seeding Finished!");
};

seedUsers();

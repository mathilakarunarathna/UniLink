import { initializeApp } from "firebase/app";
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } from "firebase/auth";
import { getFirestore, doc, setDoc, serverTimestamp } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyC5vkyaF73lJRLLDnrolzDpFHhAWaILGEA",
  authDomain: "unilink-97ccb.firebaseapp.com",
  projectId: "unilink-97ccb",
  storageBucket: "unilink-97ccb.firebasestorage.app",
  messagingSenderId: "382670272012",
  appId: "1:382670272012:web:4be228364135c737f32029"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const staffAccounts = [
  { email: "admin@unilink.com", password: "admin123", name: "Super Admin", role: "admin" },
  { email: "imanshakumudesh991@gmail.com", password: "bunny261", name: "Imansha Kumudesh", role: "cafeteria_manager" },
  { email: "security@unilink.com", password: "secpassword", name: "Campus Security", role: "security" },
  { email: "transport@unilink.com", password: "transpassword", name: "Transport Head", role: "transport_manager" }
];

async function masterSeed() {
  console.log("🌱 Starting Master Database Seeding...");
  for (const staff of staffAccounts) {
    try {
      let uid;
      console.log(`📡 Processing ${staff.email}...`);
      
      try {
        const cred = await createUserWithEmailAndPassword(auth, staff.email, staff.password);
        uid = cred.user.uid;
        console.log(`✅ Auth Created: ${staff.email}`);
      } catch (e) {
        if (e.code === 'auth/email-already-in-use') {
          const cred = await signInWithEmailAndPassword(auth, staff.email, staff.password);
          uid = cred.user.uid;
          console.log(`⚠️ Auth Exists: ${staff.email} (Linked successfully)`);
        } else if (e.code === 'auth/invalid-credential') {
            console.log(`❌ Auth Error: WRONG PASSWORD in Firebase Auth for existing account ${staff.email}.`);
            console.log(`💡 NOTE: Please manually reset password in Firebase Console or use 'Forgot Password' in UI.`);
            continue;
        } else {
          throw e;
        }
      }

      if (uid) {
        await setDoc(doc(db, "users", uid), {
          uid: uid,
          name: staff.name,
          email: staff.email,
          role: staff.role,
          approvedByAdmin: true,
          createdAt: serverTimestamp()
        }, { merge: true });
        console.log(`✅ Firestore Profile Seeded: ${staff.role}`);
      }
    } catch (err) {
      console.error(`❌ Error for ${staff.email}:`, err.message);
    }
  }
  console.log("🏁 Master Seeding Complete!");
}

masterSeed();

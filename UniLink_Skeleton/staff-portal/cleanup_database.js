import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs, deleteDoc, doc } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyC5vkyaF73lJRLLDnrolzDpFHhAWaILGEA",
  authDomain: "unilink-97ccb.firebaseapp.com",
  projectId: "unilink-97ccb",
  storageBucket: "unilink-97ccb.firebasestorage.app",
  messagingSenderId: "382670272012",
  appId: "1:382670272012:web:4be228364135c737f32029"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function cleanup() {
  console.log("🧹 Starting Firestore 'users' collection cleanup...");
  try {
    const snap = await getDocs(collection(db, "users"));
    if (snap.empty) {
      console.log("ℹ️ No users found to delete.");
      return;
    }

    let deletedCount = 0;
    const deletePromises = snap.docs.map(async (d) => {
      await deleteDoc(doc(db, "users", d.id));
      deletedCount++;
      console.log(`🗑️ Deleted: ${d.id}`);
    });

    await Promise.all(deletePromises);
    console.log(`✅ Cleanup finished! Total deleted: ${deletedCount}`);
  } catch (err) {
    console.error("❌ Cleanup failed:", err.message);
  }
}

cleanup();

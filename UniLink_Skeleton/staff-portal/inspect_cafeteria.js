import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs } from "firebase/firestore";

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

async function inspectCafeteriaData() {
  console.log("🧐 Inspecting Cafeteria Data...");
  
  console.log("\n--- SHOPS ---");
  const shopsSnap = await getDocs(collection(db, "cafeteria_shops"));
  shopsSnap.forEach(doc => {
    console.log(`🏪 [${doc.id}] ${doc.data().shopName} (${doc.data().shopEmail})`);
  });

  console.log("\n--- MENU ITEMS (First 10) ---");
  const menuSnap = await getDocs(collection(db, "cafeteria_menu"));
  let count = 0;
  menuSnap.forEach(doc => {
    if (count < 10) {
      console.log(`🍎 [${doc.id}] ${doc.data().name} - ShopID: ${doc.data().shopId}`);
    }
    count++;
  });

  console.log(`\nTotal Menu Items: ${count}`);
}

inspectCafeteriaData();

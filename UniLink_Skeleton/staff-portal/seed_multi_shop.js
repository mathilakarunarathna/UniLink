import { initializeApp } from "firebase/app";
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword } from "firebase/auth";
import { getFirestore, collection, getDocs, setDoc, doc, serverTimestamp, deleteDoc, query, where, addDoc } from "firebase/firestore";

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

const shops = [
  {
    email: "imanshakumudesh991@gmail.com",
    name: "Green Deli",
    description: "Healthy salads, fresh juices, and organic wraps.",
    category: "Healthy",
    image: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=500",
    menu: [
      { name: "Avocado Salad", price: 850, category: "Salads", description: "Fresh Hass avocado with organic greens", image: "https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=200" },
      { name: "Mango Smoothie", price: 450, category: "Drinks", description: "Tropical mango with Greek yogurt", image: "https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?q=80&w=200" }
    ]
  },
  {
    email: "spice.hub@unilink.com",
    name: "Spice Hub",
    description: "Authentic Sri Lankan rice, kottu, and biriyani.",
    category: "Fast Food",
    image: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?q=80&w=500",
    menu: [
      { name: "Chicken Biriyani", price: 1200, category: "Main", description: "Aromatic basmati with spiced chicken", image: "https://images.unsplash.com/photo-1563379091339-03b21bc4a4f8?q=80&w=200" },
      { name: "Cheese Kottu", price: 950, category: "Fast Food", description: "Wok-tossed paratha with spicy cheese sauce", image: "https://images.unsplash.com/photo-1633337474564-1d9478ca4e2e?q=80&w=200" }
    ]
  }
];

async function seedMultiShop() {
  console.log("🚀 Starting Multi-Shop Seed Processor...");
  
  // 1. Clear existing shop data to avoid conflict
  const existingShops = await getDocs(collection(db, "cafeteria_shops"));
  for (const s of existingShops.docs) await deleteDoc(doc(db, "cafeteria_shops", s.id));
  
  const existingMenu = await getDocs(collection(db, "cafeteria_menu"));
  for (const m of existingMenu.docs) await deleteDoc(doc(db, "cafeteria_menu", m.id));
  console.log("🧹 Previous cafeteria data cleared.");

  for (const shop of shops) {
    try {
      console.log(`📡 Setting up Shop: ${shop.name}...`);
      
      // Upsert Shop Document
      const shopRef = await addDoc(collection(db, "cafeteria_shops"), {
        shopName: shop.name,
        shopEmail: shop.email,
        description: shop.description,
        category: shop.category,
        image: shop.image,
        isActive: true,
        balance: 0,
        openingHours: "08:00 AM - 08:00 PM",
        createdAt: serverTimestamp()
      });

      const shopId = shopRef.id;
      console.log(`✅ Shop Created [${shopId}]`);

      // Add Menu Items for this Shop
      for (const item of shop.menu) {
        await addDoc(collection(db, "cafeteria_menu"), {
          ...item,
          shopId: shopId,
          shopName: shop.name,
          currency: "LKR",
          status: "Available",
          preparationMinutes: 15,
          quantity: 50,
          createdAt: serverTimestamp()
        });
        console.log(`   🍎 Added Menu Item: ${item.name}`);
      }
    } catch (err) {
      console.error(`❌ Error for ${shop.name}:`, err.message);
    }
  }
  
  console.log("🏁 Multi-Shop Seeding Complete!");
}

seedMultiShop();

import { initializeApp } from "firebase/app";
import { getAuth, signInWithEmailAndPassword, fetchSignInMethodsForEmail } from "firebase/auth";
import { getFirestore, doc, getDoc } from "firebase/firestore";

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

const user = {
    email: "imanshakumudesh991@gmail.com",
    password: "bunny261"
};

async function diagnose() {
    console.log(`🔍 Diagnosing ${user.email}...`);
    try {
        // 1. Try signing in
        try {
            const cred = await signInWithEmailAndPassword(auth, user.email, user.password);
            console.log("✅ Sign-in successful! User UID:", cred.user.uid);

            // Check Firestore
            const snap = await getDoc(doc(db, "users", cred.user.uid));
            if (snap.exists()) {
                console.log("📄 Firestore Profile found:", snap.data());
            } else {
                console.log("❌ Firestore Profile MISSING for this UID.");
            }
        } catch (e) {
            console.log("❌ Sign-in FAILED with code:", e.code);
            if (e.code === 'auth/invalid-credential' || e.code === 'auth/wrong-password') {
                console.log("💡 The password provided ('bunny261') does not match what's in Firebase Auth.");
            } else if (e.code === 'auth/user-not-found') {
                console.log("💡 The user does not exist in Firebase Auth.");
            }
        }
    } catch (err) {
        console.error("❌ Diagnostic error:", err.message);
    }
}

diagnose();

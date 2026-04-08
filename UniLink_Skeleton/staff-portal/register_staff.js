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

const user = {
    email: "imanshakumudesh991@gmail.com",
    password: "bunny261",
    name: "Imansha Kumudesh",
    role: "cafeteria_manager"
};

async function registerUser() {
    console.log(`🚀 Registering account: ${user.email}...`);
    try {
        let uid;
        try {
            const cred = await createUserWithEmailAndPassword(auth, user.email, user.password);
            uid = cred.user.uid;
            console.log("✅ Created Auth user.");
        } catch (e) {
            if (e.code === 'auth/email-already-in-use') {
                const cred = await signInWithEmailAndPassword(auth, user.email, user.password);
                uid = cred.user.uid;
                console.log("⚠️ Auth user already exists. Updating Firestore profile...");
            } else {
                throw e;
            }
        }

        if (uid) {
            await setDoc(doc(db, "users", uid), {
                uid: uid,
                name: user.name,
                email: user.email,
                role: user.role,
                approvedByAdmin: true,
                lastUpdated: serverTimestamp()
            }, { merge: true });
            console.log("✅ Profile linked and status set to 'Approved'.");
            console.log("🏁 You can now sign in on the portal.");
        }
    } catch (err) {
        console.error("❌ Error:", err.message);
    }
}

registerUser();

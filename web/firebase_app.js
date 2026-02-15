import { initializeApp } from "https://www.gstatic.com/firebasejs/10.11.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/10.11.0/firebase-analytics.js";

const firebaseConfig = {
apiKey: "AIzaSyCAWqtQ_yzPXn67ksiXQ4jZc_TOWCfVeto",
authDomain: "neurotrack-bad2f.firebaseapp.com",
projectId: "neurotrack-bad2f",
storageBucket: "neurotrack-bad2f.appspot.com",
messagingSenderId: "191881385523",
appId: "1:191881385523:web:de472c2073f41ee2897546",
measurementId: "G-3SXKVWRF9Q"
};

export const firebaseApp = initializeApp(firebaseConfig);
getAnalytics(firebaseApp);

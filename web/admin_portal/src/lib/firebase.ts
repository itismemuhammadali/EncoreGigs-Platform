import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyChynuewEnIYF376H9BDQr87BMtBmZmgjQ",
  authDomain: "onlygigz-33557.firebaseapp.com",
  projectId: "onlygigz-33557",
  storageBucket: "onlygigz-33557.firebasestorage.app",
  messagingSenderId: "941385767816",
  appId: "1:941385767816:web:cb0d9a49949215ad42383d",
};

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

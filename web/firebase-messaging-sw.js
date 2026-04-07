importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCnTb8HEx-YCPgEXhldVBSOOo0Smkc-4d0',
  appId: '1:722838385103:web:374eeabc11b60679f362ba',
  messagingSenderId: '722838385103',
  projectId: 'qms-system-9267a',
  storageBucket: 'qms-system-9267a.firebasestorage.app',
  authDomain: 'qms-system-9267a.firebaseapp.com',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || 'PresensiQMS';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

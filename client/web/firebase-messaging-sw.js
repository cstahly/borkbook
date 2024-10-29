importScripts('https://www.gstatic.com/firebasejs/9.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.1.0/firebase-messaging-compat.js');

firebase.initializeApp({
    "projectId": "borkbook-35422",
    "appId": "1:1007477594478:web:45e7aa9e9c48255a0cc97f",
    "storageBucket": "borkbook-35422.appspot.com",
    "apiKey": "AIzaSyBOx5Z9aMJDN9dDjZoxOVaRw5bitNNU130",
    "authDomain": "borkbook-35422.firebaseapp.com",
    "messagingSenderId": "1007477594478",
    "measurementId": "G-WFN7R4R7N8"
  });

// Retrieve an instance of Firebase Messaging to handle background messages
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png', // Set an appropriate icon for your app
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});


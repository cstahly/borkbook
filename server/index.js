const express = require('express');
const cors = require('cors'); // Import cors middleware
const fs = require('fs');
const https = require('https');
const admin = require('firebase-admin'); // Import Firebase Admin SDK

// Initialize Firebase Admin
const serviceAccount = require('/home/ec2-user/borkbook-firebase.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
const port = 4444;
app.use(express.json());

// Use CORS middleware
app.use(cors({
  origin: 'https://freepuppyservices.com', // Specify the allowed origin for security
  methods: ['GET', 'POST'],
}));

let tokens = []; // To store device tokens
const mealsFile = './meals.json';
let meals = {};
let lastUpdated = new Date();

// Reset meal data
app.get('/reset', async (req, res) => {
  meals = {
    "Precious": {
      "Monday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Tuesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Wednesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Thursday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Friday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Saturday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Sunday": { "Breakfast": false, "Lunch": false, "Dinner": false },
    },
    "Tucker": {
      "Monday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Tuesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Wednesday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Thursday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Friday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Saturday": { "Breakfast": false, "Lunch": false, "Dinner": false },
      "Sunday": { "Breakfast": false, "Lunch": false, "Dinner": false },
    }
  };

  try {
    await fs.promises.writeFile(mealsFile, JSON.stringify(meals, null, 2), 'utf-8');
    res.json({ message: 'Meals reset successfully!' });
  } catch (err) {
    console.error('Error resetting meals file:', err);
    res.status(500).json({ message: 'Failed to reset meals file.' });
  }
});

// Load meal data from the file at server startup
const loadMealsFromFile = (callback) => {
  fs.readFile(mealsFile, 'utf-8', (err, data) => {
    if (err) {
      console.error('Could not load meal data from file, initializing default data.', err);
      meals = {
        "Precious": { "Monday": { "Breakfast": false, "Lunch": false, "Dinner": false } /* other days */ },
        "Tucker": { "Monday": { "Breakfast": false, "Lunch": false, "Dinner": false } /* other days */ }
      };
      saveMealsToFile();
    } else {
      meals = JSON.parse(data);
      console.log('Meal data loaded from file.');
    }
    if (callback) callback();
  });
};

// Save the current meal data to the file
const saveMealsToFile = () => {
  fs.writeFile(mealsFile, JSON.stringify(meals, null, 2), 'utf-8', (err) => {
    if (err) {
      console.error('Error writing meal data to file:', err);
    } else {
      console.log('Meal data saved to file.');
    }
  });
};

// Routes to get the meal data and last update time
app.get('/meals', (req, res) => {
  res.json(meals);
});

app.get('/last-updated', (req, res) => {
  res.json({ last_updated: lastUpdated });
});

// Route to update the meal data
app.post('/meals', async (req, res) => {
  const { dog, day, meal, fed } = req.body;
  const properMeal = meal.charAt(0).toUpperCase() + meal.slice(1);

  if (meals[dog] && meals[dog][day]) {
    meals[dog][day][properMeal] = fed;
    lastUpdated = new Date();
    await saveMealsToFile();
    return res.json({ message: 'Meal updated successfully!' });
  } else {
    return res.status(400).json({ message: 'Invalid data provided!' });
  }
});

// Endpoint to register device tokens
app.post('/register-token', (req, res) => {
  const { token } = req.body;
  if (!token) return res.status(400).send('Token is missing');
  if (!tokens.includes(token)) tokens.push(token);
  res.status(200).send('Token registered');
});

// Endpoint to send notification to all devices except the sender
app.post('/send-notification', async (req, res) => {
  const { message: bodyMessage } = req.body;
  const senderToken = req.headers['sender-token'];

  // Filter out the sender's token
  const recipientTokens = tokens.filter((token) => token !== senderToken);

  if (recipientTokens.length === 0) {
    return res.status(400).send('No recipients to notify');
  }

  // Define base message structure for notifications
  const baseMessage = {
    notification: {
      title: 'BorkBook',
      body: bodyMessage,
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };

  let successCount = 0;
  let failureCount = 0;

  // Send notification to each recipient token
  for (const token of recipientTokens) {
    try {
      const message = { ...baseMessage, token }; // Structure for each recipient
      await admin.messaging().send(message);
      console.log(`Notification sent successfully to token: ${token}`);
      successCount++;
    } catch (error) {
      console.error(`Error sending to token ${token}:`, error);
      failureCount++;

      // Handle invalid tokens
      if (
        error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered'
      ) {
        tokens = tokens.filter((t) => t !== token);
      }
    }
  }

  // Send response based on success/failure count
  if (failureCount > 0) {
    return res.status(500).send(`${failureCount} notifications failed to send, ${successCount} sent successfully.`);
  }

  res.status(200).send('All notifications sent successfully');
});

// Load SSL certificates
const sslOptions = {
  key: fs.readFileSync('/etc/letsencrypt/live/freepuppyservices.com/privkey.pem', 'utf8'),
  cert: fs.readFileSync('/etc/letsencrypt/live/freepuppyservices.com/fullchain.pem', 'utf8')
};

// Start the HTTPS server
https.createServer(sslOptions, app).listen(port, () => {
  console.log(`HTTPS Server running on port ${port}`);
});

// Load meal data before starting the server
loadMealsFromFile(() => {
  console.log('Server is set up and ready.');
});


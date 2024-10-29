const express = require('express');
const cors = require('cors'); // Import cors middleware
const fs = require('fs');
const app = express();
const port = 4444;
const https = require('https');

const admin = require('firebase-admin');
app.use(express.json());

// Use CORS middleware
app.use(cors({
  origin: 'https://freepuppyservices.com', // Specify the allowed origin for security
  methods: ['GET', 'POST'],
}));

// Initialize Firebase Admin
const serviceAccount = require('/home/ec2-user/borkbook-firebase.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

let tokens = []; // To store device tokens

const mealsFile = './meals.json';
let meals = {};
let lastUpdated = new Date();

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
    await fs.writeFile(mealsFile, JSON.stringify(meals, null, 2), 'utf-8');
    res.json({ message: 'Meals reset successfully!' });
  } catch (err) {
    console.error('Error resetting meals file:', err);
    res.status(500).json({ message: 'Failed to reset meals file.' });
  }
});

// Load meal data from the file at server startup
const loadMealsFromFile = () => {
  fs.readFile(mealsFile, 'utf-8', (err, data) => {
    if (err) {
      console.error('Could not load meal data from file, initializing default data.', err);
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
      // Save default data to file
      saveMealsToFile();
    } else {
      meals = JSON.parse(data);
      console.log('Meal data loaded from file.');
    }
  });
};

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
  console.log(`Meal request: ${JSON.stringify(meals)}`);
  res.json(meals);
});

app.get('/last-updated', (req, res) => {
  console.log(`Last update request: ${JSON.stringify(req.body)}`);
  res.json({ last_updated: lastUpdated });
});

// Route to update the meal data
app.post('/meals', async (req, res) => {
  const { dog, day, meal, fed } = req.body;

  const properMeal = meal.charAt(0).toUpperCase() + meal.slice(1);

  console.log('meals[dog]: '+JSON.stringify(meals[dog]));
  console.log('meals[dog][day]: '+JSON.stringify(meals[dog][day]));

  if (meals[dog] && meals[dog][day]) {
    meals[dog][day][properMeal] = fed;
    lastUpdated = new Date();

    // Save the updated meal data to file
    await saveMealsToFile();

    return res.json({ message: 'Meal updated successfully!' });
  } else {
    return res.status(400).json({ message: 'Invalid data provided!' });
  }
});

// Endpoint to register device tokens
app.post('/register-token', (req, res) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).send('Token is missing');
  }

  if (!tokens.includes(token)) {
    tokens.push(token);
    console.log(`Token registered: ${token}`);
  } else {
    console.log(`Token already registered: ${token}`);
  }

  res.status(200).send('Token registered');
});

// Endpoint to send notification to all devices except the sender
app.post('/send-notification', (req, res) => {
  const { message } = req.body;
  const senderToken = req.headers['sender-token'];

  // Filter out the sender's token
  const recipientTokens = tokens.filter((token) => token !== senderToken);

  const payload = {
    notification: {
      title: 'BorkBook',
      body: message,
    },
  };

  admin
    .messaging()
    .sendToDevice(recipientTokens, payload)
    .then((response) => {
      console.log('Notification sent successfully:', response);
      res.status(200).send('Notification sent');
    })
    .catch((error) => {
      console.error('Error sending notification:', error);
      res.status(500).send('Error sending notification');
    });
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

